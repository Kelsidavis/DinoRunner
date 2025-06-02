# Dino Runner by Kelsi Davis

# --- Title Art Function ---
function Show-TitleArt {
@"
              Dino Runner by Kelsi Davis

       __
      /oo\
     |    |
 ^^  (vvvv)   ^^
 \\  /\__/\  //
  \\/      \//
   /        \        
  |          |    ^  
  /          \___/ | 
 (            )     |
  \----------/     /
    //    \\_____/
   W       W

                  Roarr!
"@ | Write-Host -ForegroundColor Green
}

# --- Game Variables (Script Scope) ---
Set-Variable -Name width -Value 40 -Scope Script
Set-Variable -Name ground -Value 6 -Scope Script
Set-Variable -Name playerX -Value 6 -Scope Script
Set-Variable -Name playerY -Value $ground -Scope Script
Set-Variable -Name jumpHeight -Value 3 -Scope Script
Set-Variable -Name velocity -Value 0 -Scope Script
Set-Variable -Name jumping -Value $false -Scope Script
Set-Variable -Name gravity -Value -1 -Scope Script
Set-Variable -Name score -Value 0 -Scope Script
Set-Variable -Name gameover -Value $false -Scope Script
Set-Variable -Name obstacles -Value @() -Scope Script
Set-Variable -Name atmosphere -Value @() -Scope Script
Set-Variable -Name lastObstacleX -Value -99 -Scope Script

# --- Drawing Function ---
function Draw {
    Clear-Host
    for ($y = 0; $y -le $script:ground; $y++) {
        $line = ""
        for ($x = 0; $x -lt $script:width; $x++) {
            $char = " "
            # Player
            if ($x -eq $script:playerX -and $y -eq $script:playerY) {
                $char = "@"
            } else {
                # Obstacles
                $obHere = $null
                foreach ($ob in $script:obstacles) {
                    if ($ob -and $ob.X -eq $x -and $ob.Y -eq $y) { $obHere = $ob; break }
                }
                if ($obHere) {
                    switch ($obHere.Type) {
                        "Cactus" { $char = "#" }
                        "Bird"   { $char = "v" }
                        default  { $char = "#" }
                    }
                } else {
                    # Clouds
                    $cloudHere = $null
                    foreach ($c in $script:atmosphere) {
                        if ($c -and $c.X -eq $x -and $c.Y -eq $y) { $cloudHere = $c; break }
                    }
                    if ($cloudHere) {
                        $char = "~"
                    } elseif ($y -eq $script:ground) {
                        $char = "_"
                    }
                }
            }
            $line += $char
        }
        Write-Host $line
    }
    Write-Host "`nScore: $($script:score)"
}

# --- Obstacle and Atmosphere Update Function ---
function UpdateObstacles {
    # Move left if valid
    if ($script:obstacles.Count -gt 0) {
        foreach ($o in $script:obstacles) { if ($o) { $o.X-- } }
    }
    if ($script:atmosphere.Count -gt 0) {
        foreach ($a in $script:atmosphere) { if ($a) { $a.X-- } }
    }
    # Remove out-of-bounds, force arrays
    $script:obstacles = @($script:obstacles | Where-Object { $_ -and $_.X -ge 0 })
    $script:atmosphere = @($script:atmosphere | Where-Object { $_ -and $_.X -ge 0 })
    # Last obstacle X for spacing
    if ($script:obstacles.Count -gt 0) {
        $last = $script:obstacles | Where-Object { $_ } | Sort-Object X | Select-Object -Last 1
        $script:lastObstacleX = if ($last) { $last.X } else { -99 }
    } else {
        $script:lastObstacleX = -99
    }
    # Add cactus
    if ((Get-Random -Minimum 0 -Maximum 6) -eq 0 -and ($script:width - $script:lastObstacleX -gt 12)) {
        $script:obstacles += [PSCustomObject]@{ X = $script:width-1; Y = $script:ground; Type = "Cactus" }
        $script:lastObstacleX = $script:width-1
    }
    # Add bird
    if ((Get-Random -Minimum 0 -Maximum 35) -eq 0) {
        $script:obstacles += [PSCustomObject]@{ X = $script:width-1; Y = $script:ground-2; Type = "Bird" }
    }
    # Add cloud
    if ((Get-Random -Minimum 0 -Maximum 18) -eq 0) {
        $script:atmosphere += [PSCustomObject]@{ X = $script:width-1; Y = (Get-Random -Minimum 0 -Maximum ($script:ground-3)) }
    }
}

# --- Collision Check Function ---
function CheckCollision {
    foreach ($ob in $script:obstacles) {
        if ($ob -and $ob.Type -eq "Cactus" -and $ob.X -eq $script:playerX -and $ob.Y -eq $script:playerY) { return $true }
        if ($ob -and $ob.Type -eq "Bird" -and $ob.X -eq $script:playerX -and $ob.Y -eq $script:playerY) { return $true }
    }
    return $false
}

# --- Main Game Loop ---
function MainLoop {
    try {
        while (-not $script:gameover) {
            # Input for jump
            if ([console]::KeyAvailable) {
                $key = [console]::ReadKey($true)
                if ($key.Key -eq 'Spacebar' -and -not $script:jumping -and $script:playerY -eq $script:ground) {
                    $script:velocity = 3
                    $script:jumping = $true
                    [console]::beep(1040, 80)
                }
                elseif ($key.Key -eq 'Escape') {
                    $script:gameover = $true
                    break
                }
            }

            # Physics for jump
            if ($script:jumping) {
                $script:playerY -= $script:velocity
                $script:velocity += $script:gravity
                if ($script:playerY -ge $script:ground) {
                    $script:playerY = $script:ground
                    $script:jumping = $false
                    $script:velocity = 0
                }
                elseif ($script:playerY -lt ($script:ground - $script:jumpHeight)) {
                    $script:playerY = $script:ground - $script:jumpHeight
                    $script:velocity = 0
                }
            }

            UpdateObstacles

            if (CheckCollision) {
                Draw
                1..5 | ForEach-Object { [console]::beep(900 - $_*150, 60) }
                Write-Host "`nGame Over! Final score: $($script:score)" -ForegroundColor Red
                Write-Host "Press ENTER to exit..."
                [void][System.Console]::ReadLine()
                break
            }

            Draw
            $script:score++
            Start-Sleep -Milliseconds 80
        }
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Press ENTER to exit..."
        [void][System.Console]::ReadLine()
    }
}

# --- Title Screen & Start ---
Clear-Host
Show-TitleArt
Write-Host "Jump over cactuses (#) and birds (v), enjoy the clouds (~)!" -ForegroundColor Yellow
Write-Host "Jump with SPACEBAR. Press ESC to quit." -ForegroundColor Cyan
Write-Host ""
Write-Host "Press ENTER to start..."
[void][System.Console]::ReadLine()

MainLoop
