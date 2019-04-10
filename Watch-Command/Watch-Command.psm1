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
        [Alias('Replay','Watch','Command')]
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
            $esc = [char]27
            $setCursorTop = "$esc[0;0H"
            $hideCursor = "$esc[?25l"
            $showCursor = "$esc[?25h"
            $message = "{0:HH:mm:ss} Refresh {1}: {2,-60}" -f (Get-Date),$Seconds, $ScriptBlock.ToString()
            $output = $ScriptBlock.Invoke() | Out-String -Stream
            
            Write-Host "$hideCursor${setCursorTop}" -NoNewline
            Write-Host "$message"

            for($index = 1; $index -lt $Host.UI.rawui.WindowSize.Height - 1;$index++ )
            {
                if($ShowChanges)
                {
                    if($output[$index] -ne $previous[$index])
                    {
                        Write-Host $output[$index] -BackgroundColor DarkGreen
                    }
                    elseif($output[$index] -ne $ghost[$index])
                    {
                        Write-Host $output[$index] -BackgroundColor DarkCyan
                    }
                    else
                    {
                        Write-Host $output[$index]
                    }
                }
                else
                {
                    Write-Host $output[$index]
                }
            }
            Write-Host $showCursor -NoNewline
            Start-Sleep -Seconds $Seconds
            $ghost = $previous
            $previous = $output
        }
    }
}