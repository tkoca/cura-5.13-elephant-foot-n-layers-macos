-- Install / Uninstall app of the .dmg: runs the bundled installer/efnl.sh with --gui.
-- @ACTION@ is replaced by install or uninstall at build time (scripts/build-dmg.sh).
-- The installer shows its own questions, progress and results; nothing to type.
on run
	set efnl to POSIX path of (path to me) & "Contents/Resources/installer/efnl.sh"
	activate
	try
		do shell script "/bin/bash " & quoted form of efnl & " @ACTION@ --gui"
	end try
end run
