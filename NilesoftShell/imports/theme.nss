theme
{
	// theme.name = auto, classic, white, black, or modern
	name = "black"

	// view = auto, compact, small, medium, large, wide
	view = small

	// dark = true, false, default
	dark = true

	background
	{
		color = #000000
		opacity = 0
		// effect value 0 = disable, 1 = transparent, 2 = blur, 3 = acrylic
		effect = 0
	}
	image.align=2

	item
	{
		opacity = 0
		radius = 0
		// prefix value [auto, 0 = dont display,  1 = display, 2 = ignore]
		prefix = 1

		text
		{
			normal = #F0F000
			normal.disabled = #969600  
			select = #F0F000
			select.disabled = #969600
		}

		back
		{
			normal = #000000
			normal.disabled = #000000
			select = #000000
			select.disabled = #000000
		}

		border
		{
			normal = #000000
			normal.disabled = #000000
			select = #F0F000
			select.disabled = #F0F000
		}
	}

	border
	{
		enabled = true
		size = 1
		color = #F0F000 
		radius = 0
	}
	 
	shadow
	{
		enabled = false 
	}

	separator
	{
		size = 1
		color = #969600
	}

  image
	{
		enabled = false
	}

	symbol
	{
		normal = #F0F000 
		normal.disabled = #969600 
		select = #F0F000 
		select.disabled = #969600 

		chevron
		{
			normal = #F0F000 
			normal.disabled = #969600 
			select = #F0F000 
			select.disabled = #969600 
		}

		checkmark
		{
			normal = #F0F000 
			normal.disabled = #969600 
			select = #F0F000 
			select.disabled = #969600 
		}

		bullet
		{
			normal = #F0F000 
			normal.disabled = #969600 
			select = #F0F000 
			select.disabled = #969600 
		}
	}
}