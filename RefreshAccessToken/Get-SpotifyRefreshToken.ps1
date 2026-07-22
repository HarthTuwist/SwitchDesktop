<#
	FROM CLAUDE

    Get-SpotifyRefreshToken.ps1

    Obtains a Spotify *refresh token* using the OAuth 2.0 Authorization Code Flow,
    following the protocol from:
        https://dev.to/moezarella/how-to-get-a-spotify-refresh-token-1min

    The flow:
        1. Build the authorize URL and open it in the browser.
        2. The user logs in / approves. Spotify redirects to the local
           redirect URI with a ?code=... parameter.
        3. A local HttpListener captures that authorization code
           (this replaces the little node "Hello World" server on port 8888).
        4. The code is exchanged for tokens at the token endpoint.
        5. The full token response is saved next to the other secrets and the
           refresh token is printed.

    Credentials are read from ..\Secrets\Base64IdSecret.json which holds the
    pre-computed "Basic <base64(client_id:client_secret)>" Authorization header.
    Nothing else is required.
#>

[CmdletBinding()]
param(
    # Must EXACTLY match a Redirect URI registered in your Spotify app dashboard.
    # Port 8888 matches the existing SpotifyWebTarget.js listener.
    [string]$RedirectUri = 'http://127.0.0.1:8888/callback',

    # Space-separated scopes. Defaults to the scopes of the original token.
    [string]$Scope = 'user-modify-playback-state user-library-modify playlist-modify-public user-read-playback-state'
)

$ErrorActionPreference = 'Stop'

# System.Web provides HttpUtility for safe URL-encoding of the query string.
Add-Type -AssemblyName System.Web

# --- Locate the Secrets folder (sibling of this script's parent) ------------
$SecretsDir = Join-Path $PSScriptRoot '..\Secrets'
$SecretsDir = [System.IO.Path]::GetFullPath($SecretsDir)
if (-not (Test-Path $SecretsDir)) {
    throw "Secrets folder not found at: $SecretsDir"
}

# --- Read the Basic auth header and recover the client_id -------------------
$idSecretFile = Join-Path $SecretsDir 'Base64IdSecret.json'
$basicAuth = (Get-Content -Raw -Path $idSecretFile | ConvertFrom-Json).idsecretb64
if ([string]::IsNullOrWhiteSpace($basicAuth)) {
    throw "Could not read 'idsecretb64' from $idSecretFile"
}

# "Basic <b64>" -> decode "client_id:client_secret" -> client_id
$b64 = $basicAuth -replace '^\s*Basic\s+', ''
$pair = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
$ClientId = $pair.Split(':', 2)[0]
if ([string]::IsNullOrWhiteSpace($ClientId)) {
    throw "Could not decode client_id from the Basic auth header."
}

Write-Host "Client ID    : $ClientId"
Write-Host "Redirect URI : $RedirectUri"
Write-Host "Scopes       : $Scope"
Write-Host ""

# --- Step 2: Build the authorization URL ------------------------------------
$state = [Guid]::NewGuid().ToString('N')
$query = [System.Web.HttpUtility]::ParseQueryString('')
$query['response_type'] = 'code'
$query['client_id']     = $ClientId
$query['scope']         = $Scope
$query['redirect_uri']  = $RedirectUri
$query['state']         = $state
$authUrl = 'https://accounts.spotify.com/authorize?' + $query.ToString()

# --- Step 3: Start local listener to capture the redirect -------------------
# HttpListener prefixes require a trailing slash on the path.
$prefix = $RedirectUri
if ($prefix -notmatch '/$') { $prefix += '/' }

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
}
catch {
    throw "Failed to start HttpListener on '$prefix'. Make sure the port is free " +
          "and that the RedirectUri matches your Spotify dashboard. Error: $($_.Exception.Message)"
}
Write-Host "Listening for the Spotify redirect on $prefix"

# Open the browser for the user to authorize.
Write-Host "Opening browser for authorization..."
Start-Process $authUrl

Write-Host "Waiting for Spotify to redirect back (approve access in the browser)..."
$context  = $listener.GetContext()          # blocks until the redirect arrives
$request  = $context.Request
$response = $context.Response

$code       = $request.QueryString['code']
$stateBack  = $request.QueryString['state']
$errorParam = $request.QueryString['error']

# Send a friendly page back to the browser, then stop listening.
$html = if ($code) {
    '<html><body style="font-family:sans-serif"><h2>Authorization received.</h2><p>You can close this tab and return to PowerShell.</p></body></html>'
} else {
    "<html><body style='font-family:sans-serif'><h2>Authorization failed.</h2><p>$errorParam</p></body></html>"
}
$buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
$response.ContentType = 'text/html'
$response.ContentLength64 = $buffer.Length
$response.OutputStream.Write($buffer, 0, $buffer.Length)
$response.OutputStream.Close()
$listener.Stop()

if ($errorParam) { throw "Spotify returned an error: $errorParam" }
if ($stateBack -ne $state) { throw "State mismatch (possible CSRF). Expected '$state', got '$stateBack'." }
if ([string]::IsNullOrWhiteSpace($code)) { throw "No authorization code was returned." }

Write-Host "Authorization code received."

# --- Step 4: Exchange the code for tokens -----------------------------------
$tokenBody = @{
    grant_type   = 'authorization_code'
    code         = $code
    redirect_uri = $RedirectUri
}

$tokenResponse = Invoke-RestMethod -Method Post `
    -Uri 'https://accounts.spotify.com/api/token' `
    -Headers @{ Authorization = "Basic $b64" } `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body $tokenBody

# --- Step 5: Save and report -------------------------------------------------
$outFile = Join-Path $SecretsDir 'OriginalAccessToken.json'
$tokenResponse | ConvertTo-Json -Depth 5 | Set-Content -Path $outFile -Encoding UTF8

Write-Host ""
Write-Host "======================================================================"
Write-Host "SUCCESS - tokens saved to: $outFile"
Write-Host "----------------------------------------------------------------------"
Write-Host "Refresh token:"
Write-Host $tokenResponse.refresh_token
Write-Host "----------------------------------------------------------------------"
Write-Host "Access token expires in $($tokenResponse.expires_in) seconds."
Write-Host "Granted scopes: $($tokenResponse.scope)"
Write-Host "======================================================================"
