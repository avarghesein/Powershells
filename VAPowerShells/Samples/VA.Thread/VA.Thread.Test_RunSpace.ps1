#Print Main Process/Thread ID
$curthrd = "" + [System.Diagnostics.Process]::GetCurrentProcess().Id + ";" + [System.Threading.Thread]::CurrentThread.ManagedThreadId


#Threading in Powershell with RunSpace Pool - Similar to a ThreadPool
$threadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]
#Create a pool of 5 Threads
#$rp = [runspacefactory]::CreateRunspacePool(1,5)
#Create an empty pool (this can be used to use the calling thread and other options)
$rp = [runspacefactory]::CreateRunspacePool()
#For now use the invoking thread
$rp.ThreadOptions = $threadOptions::UseCurrentThread
$rp.open()


#Setup the pipeline to execute under the thread
$t1 = [powershell]::Create()
#Attach the thread pool with options
$t1.RunspacePool = $rp
#Setup the script to be executed for the thread
$t1.AddScript({ "" + [System.Diagnostics.Process]::GetCurrentProcess().Id + ";" + [System.Threading.Thread]::CurrentThread.ManagedThreadId } )
#$t1h = $t1.BeginInvoke()
#$t1res = $t1.EndInvoke($t1h)
#Synchronous invoke, Wait for the thread to finish (if this is running under a foreign thread)
$t1res = $t1.invoke()


#dispose the objects
$t1.Dispose()
$rp.close()
$rp.Dispose()