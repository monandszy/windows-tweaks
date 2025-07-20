menu(
	mode="multiple" 
	title='Develop'
	sep='bottom'
	pos=1
)
{
    // Code Editors
	item(
		where=sel.count // Appears if any file/folder is selected
		title='Vscodium'
		cmd='%USERPROFILE%\_MyPrograms\Programing\vscodium-portable\VSCodium.exe'
		args='"@sel.path"'
	)
	item(
		type='file'
		title='Windows notepad'
		cmd='@sys.bin\notepad.exe'
		args='"@sel.path"'
	)
    // Scripting
    item(
			where=sel.file.ext=='.ahk' // Appears only for .ahk files
			title='Run with AutoHotkey (v2)'
			cmd='%USERPROFILE%\_MyPrograms\Development\AutoHotkey_2\AutoHotkey64.exe'
			args='"@sel.path"'
    )

	separator

	// Terminals - appear when a folder is selected or in an empty space
	item(
		type='dir|back.dir'
		title='Open in cmd (Admin)'
		admin=true
		cmd='cmd.exe'
		args='/K TITLE Command Prompt & PUSHD ""@sel.path""'
	)
	item(
		type='dir|back.dir'
		title='Git Bash Here'
		cmd='%USERPROFILE%\_MyPrograms\Development\PortableGit\git-bash.exe'
		args='"@sel.path"' // Sets the starting directory for the new process
	)
	item(
		type='dir|back.dir'
		title='Git CMD Here'
		cmd='%USERPROFILE%\_MyPrograms\Development\PortableGit\git-cmd.exe'
		args='"@sel.path"' // Sets the starting directory
	)
}

menu(
	mode="multiple" 
	title='Edit or View' pos=1
	type='file'
)
{
    // This item will appear for common raster image files
	item(
		where=sel.file.ext=='.png' || sel.file.ext=='.jpg' || sel.file.ext=='.jpeg' || sel.file.ext=='.gif' || sel.file.ext=='.bmp' || sel.file.ext=='.tiff' || sel.file.ext=='.pdn'
		title='Edit with Paint.NET'
		cmd='%USERPROFILE%\_MyPrograms\Portable\PaintDotNet\PaintDotNetPortable.exe'
		args='"@sel.path"'
	)
    // This item will appear for a wide range of image files, including Photoshop's .psd
	item(
		where=sel.file.ext=='.png' || sel.file.ext=='.jpg' || sel.file.ext=='.jpeg' || sel.file.ext=='.gif' || sel.file.ext=='.bmp' || sel.file.ext=='.tiff' || sel.file.ext=='.psd' || sel.file.ext=='.xcf'
		title='Edit with GIMP'
		cmd='%USERPROFILE%\_MyPrograms\Portable\GIMPPortable\GIMPPortable.exe'
		args='"@sel.path"'
	)
    // This item will appear for vector graphics and PDFs
	item(
		where=sel.file.ext=='.svg' || sel.file.ext=='.ai' || sel.file.ext=='.eps' || sel.file.ext=='.pdf'
		title='Edit with Inkscape'
		cmd='%USERPROFILE%\_MyPrograms\Portable\Inkscape\bin\inkscape.exe'
		args='"@sel.path"'
	)
    // Appears for common audio file types
	item(
		where=sel.file.ext=='.wav' || sel.file.ext=='.mp3' || sel.file.ext=='.ogg' || sel.file.ext=='.flac' || sel.file.ext=='.aup3'
		title='Edit with Audacity'
		cmd='%USERPROFILE%\_MyPrograms\Portable\Audacity\Audacity.exe'
		args='"@sel.path"'
	)
    // Appears for common video file types
	item(
		where=sel.file.ext=='.mp4' || sel.file.ext=='.mov' || sel.file.ext=='.avi' || sel.file.ext=='.mkv' || sel.file.ext=='.webm' || sel.file.ext=='.ove'
		title='Edit with Olive Video Editor'
		cmd='%USERPROFILE%\_MyPrograms\Portable\olive-editor\olive-editor.exe'
		args='"@sel.path"'
	)
	item(
		where=sel.file.ext=='.pcap' || sel.file.ext=='.pcapng' || sel.file.ext=='.cap'
		title='Analyze with Wireshark'
		cmd='%USERPROFILE%\_MyPrograms\Programing\WiresharkPortable64\WiresharkPortable64.exe'
		args='-r "@sel.path"' // -r tells Wireshark to read a capture file on startup
	)
	item(
		where=sel.file.ext=='.pcap' || sel.file.ext=='.pcapng' || sel.file.ext=='.cap'
		title='Analyze with NetworkMiner'
		cmd='%USERPROFILE%\_MyPrograms\Programing\NetworkMiner_2-9\NetworkMiner.exe'
		args='"@sel.path"'
	)
	item(where=sel.file.ext=='.pdf' || sel.file.ext=='.epub' || sel.file.ext=='.djvu' || sel.file.ext=='.md'
	 title='View with Okular'
	 cmd='%USERPROFILE%\_MyPrograms\Portable\Okular\bin\okular.exe'
	 args='"@sel.path"'
	 )
	item(where=sel.file.ext=='.png' || sel.file.ext=='.jpg' || sel.file.ext=='.jpeg' || sel.file.ext=='.gif' || sel.file.ext=='.bmp' || sel.file.ext=='.webp' || sel.file.ext=='.ico'
	 title='View with qimgv'
	 cmd='%USERPROFILE%\_MyPrograms\Portable\qimgv-video\qimgv.exe'
	 args='"@sel.path"'
	 )
	item(where=sel.file.ext=='.mp4' || sel.file.ext=='.mkv' || sel.file.ext=='.avi' || sel.file.ext=='.mov' || sel.file.ext=='.webm' || sel.file.ext=='.flv'
	 title='Play with mpv'
	 cmd='%USERPROFILE%\_MyPrograms\Portable\qimgv-video\mpv.exe'
	 args='"@sel.path"'
	 )
	item(where=sel.file.ext=='.html' || sel.file.ext=='.htm' || sel.file.ext=='.xml' || sel.file.ext=='.svg'
	 title='View in Vivaldi'
	 cmd='%USERPROFILE%\_MyPrograms\Portable\Vivaldi\Application\vivaldi.exe'
	 args='"@sel.path"'
	 )
	item(where=sel.file.ext=='.html' || sel.file.ext=='.htm' || sel.file.ext=='.xml' || sel.file.ext=='.svg'
	 title='View in LibreWolf'
	 cmd='%USERPROFILE%\_MyPrograms\Portable\LibreWolf Portable\LibreWolf-Portable.exe'
	 args='"@sel.path"'
	 )
}