menu(type = 'file|dir|back|root|namespace'
  	mode = "multiple"
  	title = 'Copy Path'
		pos=1
  	) {
  	// Appears only when multiple selections.
  	item(vis = @(sel.count > 1) title = 'Copy path (@sel.count) items selected'
  		cmd = command.copy(sel(false, "\n")))

  	item(mode = "single"
  		title = sel.path cmd = command.copy(sel.path))
  	item(mode = "single"
  		vis = @(sel.parent.len > 3) title = sel.parent cmd = command.copy(sel.parent))
		separator
  	item(mode = "single"
  		type = 'file|dir|back.dir'
  		title = sel.file.name cmd = command.copy(sel.file.name))

  	item(mode = "single"
  		type = 'file'
  		title = sel.file.title cmd = command.copy(sel.file.title))
  }
modify(
  find="properties"
  pos=0
)
modify(
  find="new"
  pos=0
)

menu(
	mode="multiple" 
	title=title.more_options
	pos=0
	sep=bottom
	)
{
}

modify(mode=mode.multiple
	where=this.id(
		id.create_shortcut,
		id.delete,
		id.rename,
		id.copy,
		id.cut,
		id.paste,
		id.paste_shortcut,
		id.undo,
		id.redo,
		id.open_file_location
	) menu=title.more_options)