remove(find="unpin*" )
remove(find="pin*")
remove(find="Scan with*")
remove(find="3D Edit")
remove(find="Edit*")
remove(find="Open as*")
remove(find="Open")
remove(find="Run as*")
remove(find="Redo*")
remove(find="Undo*")

modify(type="dir.back|drive.back" where=this.id==id.customize_this_folder pos=1 sep="top" menu="file manage")

modify(type="recyclebin" where=window.is_desktop and this.id==id.empty_recycle_bin pos=1 sep)

remove(mode=mode.multiple
	where=this.id(
		id.send_to,
		id.share,
		id.set_as_desktop_background,
		id.rotate_left,
		id.rotate_right,
		id.give_access_to,
		id.include_in_library,
		id.print,
		id.restore_previous_versions,
		id.cast_to_device,
		id.copy_as_path,
		id.collapse,
		id.expand
	))


modify(
  find="view"
  pos=5
)
modify(
  find="sort by"
  pos=5
)
modify(
  find="group by"
  pos=5
)
modify(
  find="refresh"
  pos=5
)
modify(
  find="7-Zip"
  pos=5
)

modify(
  find="*"
  pos=6
)
