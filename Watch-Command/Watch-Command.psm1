function WriteHost 
{
    param(
        [parameter(
            position = 0,
            ValueFromPipeline
        )]
        [string]
        $Message,

        [ValidateSet('Default','Changed','Hilight')]
        $State = 'Default'
    )

    begin
    {
        $drawWidth =  $Host.UI.rawui.WindowSize.Width
        $backgroundColor = @{}
        switch($State)
        {
            'Changed'
            {
                $backgroundColor['BackgroundColor'] = 'DarkGreen'
            }
            'Hilight'
            {
                $backgroundColor['BackgroundColor'] = 'DarkCyan'
            }
        }
    }

    process
    {
        $foregroundColor = @{}
        Switch -regex ($Message)
        {
            '^ERROR:'
            {
                $foregroundColor['ForegroundColor'] = 'Red'
                $backgroundColor['BackgroundColor'] = 'Black'
            }
        }
        if($Message.Length -ge $drawWidth)
        {
            $Message = $Message.Substring(0,$drawWidth)
        }
        # Fill line with space so whole line gets color
        $formatted = "{0,-$drawWidth}" -f $Message
        Write-Host $formatted @foregroundColor @backgroundColor
    }
}

function Watch-Command
{
    <#
    .Description
    Executes a command multiple times for monitoring results

    .Notes
    The output will be trimmed to to fit your console window, Supports resizing
    you have to force quit the function or it will keep running
    #>

    [Alias('Watch')]
    [cmdletbinding()]
    param
    (
        # The command to execute each loop
        [Alias('Replay','Watch','Replay-Command')]
        [Parameter(
            Mandatory,
            Position = 0
        )]
        [scriptblock]
        $ScriptBlock,

        # how long to delay between executions
        [Alias('Delay')]
        $Seconds = 5,

        [switch]
        $ShowChanges
    )
    begin
    {
        Clear-Host
    }

    process
    {
        $previous = @()
        $ghost = @()
        while($true)
        {
            $output = @()
            $esc = [char]27
            $setCursorTop = "$esc[0;0H"
            $hideCursor = "$esc[?25l"
            $showCursor = "$esc[?25h"
            $message = "{0:HH:mm:ss} Refresh {1}: {2,-60}" -f (Get-Date),$Seconds, $ScriptBlock.ToString()

            try
            {
                $errorOffset = $error.Count
                $output = [string[]]@(& $ScriptBlock *>&1  | Out-String -Stream)

                # First line is often blank so drop it if so
                if([string]::IsNullOrWhiteSpace($output[0]))
                {
                    $output = [string[]]@($output | Select-Object -Skip 1)
                }
            }
            catch
            {
                $output = [string[]]@( 
                    # Skipping error[0] because it is our scriptblock.invoke()
                    $error.RemoveAt(0)
                    $startAt = ($error.count - $errorOffset) - 1
                    $error[$startAt..0] | Out-String -Stream | 
                        ForEach-Object{"ERROR:$_"} 
                )
            }
            
            Write-Host "$hideCursor${setCursorTop}" -NoNewline
            WriteHost "$message" -State Default

            # Need to leave room at the end so that we don't scroll console
            $drawArea =  $Host.UI.rawui.WindowSize.Height - 2
            for($index = 0; $index -lt $drawArea; $index++ )
            {
                if($ShowChanges)
                {
                    if($output[$index] -ne $previous[$index])
                    {
                        WriteHost $output[$index] -State Changed
                    }
                    elseif($output[$index] -ne $ghost[$index])
                    {
                        WriteHost $output[$index] -State Hilight
                    }
                    else
                    {
                        WriteHost $output[$index]
                    }
                }
                else
                {
                    WriteHost $output[$index]
                }
            }

            Write-Host $showCursor -NoNewline
            Start-Sleep -Seconds $Seconds
            $ghost = $previous
            $previous = $output
        }
    }
}