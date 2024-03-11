# Importar el modulo Active Directory
Import-Module ActiveDirectory

# Verificar que se proporcionen los argumentos esperados
if ($args.Count -lt 2) {
    cls
    Write-Host "Uso: .\script.ps1 <acci�n> <nombreUsuario>"
    Write-Host ""
    Write-Host "Acciones disponibles:"
    Write-Host "        chk :  Verificar estado e informacion basica"
    Write-Host "        ul  :  Desbloquea usuario en AD"
    Write-Host "        pw  :  Cambio de contrase�a"
    Write-Host ""
    exit
}

$accion = $args[0]
$nombreUsuario = $args[1]

# Validar que la accion proporcionada sea valida
if ($accion -notin @('chk', 'ul', 'pw')) {
    cls
    Write-Host "La acci�n proporcionada no es valida..."
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

        # Mostrar informaci�n del usuario
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
    'pw' {
        # Solicitar nueva contrase�a de forma segura
        $newPass = Read-Host -Prompt "Ingrese nueva contrase�a:" -AsSecureString
        # Establecer la nueva contrase�a y manejar cualquier error
        try {
            Set-ADAccountPassword -Identity $nombreUsuario -NewPassword $newPass -Reset
            Write-Host "La nueva contrase�a establecida correctamente"
        } catch {
            Write-Host "Error al establecer la nueva contrase�a: $_"
        }
    }
}
