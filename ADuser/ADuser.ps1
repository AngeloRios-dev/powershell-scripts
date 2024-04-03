<#
    Script: ADuser.ps1
    Autor: Angelo Rios

    Descripcion: Este script de PowerShell proporciona acciones para mejorar la eficiencia al
    automatizar procesos repetitivos de administracion de usuarios en el Directorio Activo.
    Desarrollado pensando en las funcionalidades que necesito en mi entorno de trabajo.


    Las acciones disponibles son:
    - Verificar el estado e informacion basica de un usuario, 
    - Desbloquear un usuario en Directorio Activo, 
    - Mostrar los grupos de pertenencia del usuario y 
    - Cambiar la contraseña del usuario.

    Fecha de creacion: 21 de febrero de 2023
    Ultima modificación: 12 de marzo de 2024
#>

# Importar el modulo Active Directory
Import-Module ActiveDirectory

# Funcion para verificar información del usuario
function VerificarUsuario {
    param(
        [string]$nombreUsuario
    )
    cls
    Write-Host "Verificando informacion del usuario:"
    $bloqueado = Get-ADUser -Identity $nombreUsuario -Properties Lockedout

    if ($bloqueado.LockedOut) {
        Write-Host "El usuario esta bloqueado. Desbloqueando..."
        Unlock-ADAccount -Identity $nombreUsuario
        Write-Host "Usuario desbloqueado exitosamente."
    } else {
        # Mostrar información del usuario
        $usuario = Get-ADUser -Identity $nombreUsuario -Properties EmployeeID, GivenName, Surname, UserPrincipalName, Enabled, Lockedout, PasswordExpired, PasswordLastSet, Created, AccountExpirationDate
        $usuario | Select-Object EmployeeID, GivenName, Surname, UserPrincipalName, Enabled, Lockedout, PasswordExpired, PasswordLastSet, Created, AccountExpirationDate
    }

    
}

# Funcion para desbloquear usuario
function DesbloquearUsuario {
    param(
        [string]$nombreUsuario
    )

    Write-Host "Desbloqueando $nombreUsuario en AD"
    Unlock-ADAccount -Identity $nombreUsuario
    # Esperar antes de verificar el estado
    Start-Sleep -Seconds 2
    # Obtener y mostrar el estado del usuario
    $userStatus = Get-ADUser -Identity $nombreUsuario -Properties Lockedout | Select-Object -ExpandProperty Lockedout

    if ($userStatus -eq $false) {
        Write-Host "Usuario desbloqueado exitosamente."
    } else {
        Write-Host "Ha habido un error. Por favor, volver a intentarlo."
    }
    Write-Host ""
}

# Funcion para mostrar grupos de pertenencia
function MostrarGruposPertenencia {
    param(
        [string]$nombreUsuario
    )

    Write-Host "Grupos a los que pertenece:"
    # Buscar los grupos de los que es miembro el usuario
    $memberOfGroups = Get-ADUser -Identity $nombreUsuario -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    # Mostrar los nombres de los grupos
    foreach ($group in $memberOfGroups) {
        $groupName = ($group -split ',')[0] -replace '^CN='
        Write-Host "- $groupName"
    }
}

# Funcion para cambio de contraseña
function CambiarContraseña {
    param(
        [string]$nombreUsuario
    )

    # Solicitar nueva contraseña de forma segura
    $newPass = Read-Host -Prompt "Ingrese nueva contraseña:" -AsSecureString
    # Establecer la nueva contraseña y manejar cualquier error
    try {
        Set-ADAccountPassword -Identity $nombreUsuario -NewPassword $newPass -Reset
        Write-Host "La nueva contraseña se establecio correctamente"
    } catch {
        Write-Host "Error al establecer la nueva contraseña: $_"
    }
}

# Verificar que se proporcionen los argumentos esperados
if ($args.Count -lt 2) {
    cls
    Write-Host "NOMBRE"
    Write-Host "    ADuser.ps1"
    Write-Host ""
    Write-Host "SINTAXIS"
    Write-Host "    ADuser.ps1 <accion> <nombreUsuario> (solo la parte anterior al @)"
    Write-Host ""
    Write-Host "ACCIONES"
    Write-Host "    chk :   Desbloquear y mostrar informacion basica"
    Write-Host "    ul  :   Solo desbloquear usuario"
    Write-Host "    mem :   Mostrar grupos de pertenencia (Miembro de)"
    Write-Host "    pw  :   Cambio de contraseña en AD"
    Write-Host ""
    exit
}

$accion = $args[0]
$nombreUsuario = $args[1]

# Validar que la accion proporcionada sea valida
if ($accion -notin @('chk', 'ul', 'mem', 'pw')) {
    cls
    Write-Host "La accion proporcionada no es valida..."
    exit
}

# Ejecutar la funcion correspondiente segun la accian proporcionada
switch ($accion) {
    'chk' { VerificarUsuario $nombreUsuario }
    'ul' { DesbloquearUsuario $nombreUsuario }
    'mem' { MostrarGruposPertenencia $nombreUsuario }
    'pw' { CambiarContraseña $nombreUsuario }
}