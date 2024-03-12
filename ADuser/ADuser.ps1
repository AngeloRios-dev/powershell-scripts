<#
    Script: ADuser.ps1
    Autor: Angelo Rios

    Descripción: Este script de PowerShell proporciona acciones para mejorar la eficiencia al
    automatizar procesos repetitivos de administracion de usuarios en el Directorio Activo.
    Desarrollado pensando en las funcionalidades que necesito en mi entorno de trabajo.


    Las acciones disponibles incluyen 
    - verificar el estado e información básica de un usuario, 
    - desbloquear un usuario en Active Directory, 
    - mostrar los grupos de pertenencia del usuario y 
    - cambiar la contraseña del usuario.

    Fecha de creación: 21 de febrero de 2023
    Última modificación: 12 de marzo de 2024
#>

# Importar el modulo Active Directory
Import-Module ActiveDirectory

# Verificar que se proporcionen los argumentos esperados
if ($args.Count -lt 2) {
    cls
    Write-Host "Uso: .\script.ps1 <acción> <nombreUsuario>"
    Write-Host ""
    Write-Host "Acciones disponibles:"
    Write-Host "        chk :  Verificar estado e informacion basica"
    Write-Host "        ul  :  Desbloquea usuario en AD"
    Write-Host "        mem  : Mostrar grupos de pertenencia"
    Write-Host "        pw  :  Cambio de contraseña"
    Write-Host ""
    exit
}

$accion = $args[0]
$nombreUsuario = $args[1]

# Validar que la accion proporcionada sea valida
if ($accion -notin @('chk', 'ul', 'mem', 'pw')) {
    cls
    Write-Host "La acción proporcionada no es valida..."
    exit
}

switch ($accion) {
    'chk' {
        cls
        Write-Host "Verificar informacion del usuario:"
        # Buscar las propiedades que nos interesan
        $usuario = Get-ADUser -Identity $nombreUsuario -Properties EmployeeID, GivenName, Surname, UserPrincipalName, Enabled, Lockedout, PasswordExpired, PasswordLastSet, Created, AccountExpirationDate

        if ($usuario.LockedOut) {
            Write-Host "El usuario esta bloqueado. Desbloqueando..."
            Unlock-ADAccount -Identity $nombreUsuario
            Write-Host "Usuario desbloqueado."
        }

        # Mostrar información del usuario
        $usuario | Select-Object EmployeeID, GivenName, Surname, UserPrincipalName, Enabled, Lockedout, PasswordExpired, PasswordLastSet, Created, AccountExpirationDate
    } 
    'ul' {
        cls
        Write-Host "Desbloquear $nombreUsuario en AD"
        Unlock-ADAccount -Identity $nombreUsuario
        # Esperar antes de verificar el estado
        Start-Sleep -Seconds 2
        Write-Host ""
        # Obtener y mostrar el estado del usuario
        $userStatus = Get-ADUser -Identity $nombreUsuario -Properties Lockedout | Select-Object -ExpandProperty Lockedout

        if ($userStatus -eq $false) {
            Write-Host "Usuario desbloqueado exitosamente"
        } else {
            Write-Host "Ha habido un error, volver a intentarlo"
        }
    }
    'mem' {
        cls
        Write-Host "Grupos a los que pertenece:"
        # Buscar los grupos de los que es miembro el usuario
        $memberOfGroups = Get-ADUser -Identity $nombreUsuario -Properties MemberOf | Select-Object -ExpandProperty MemberOf
        # Mostrar los nombres de los grupos
        foreach ($group in $memberOfGroups) {
            $groupName = ($group -split ',')[0] -replace '^CN='
            Write-Host "- $groupName"
        }
    }
     
    'pw' {
        # Solicitar nueva contraseña de forma segura
        $newPass = Read-Host -Prompt "Ingrese nueva contraseña:" -AsSecureString
        # Establecer la nueva contraseña y manejar cualquier error
        try {
            Set-ADAccountPassword -Identity $nombreUsuario -NewPassword $newPass -Reset
            Write-Host "La nueva contraseña establecida correctamente"
        } catch {
            Write-Host "Error al establecer la nueva contraseña: $_"
        }
    }
}
