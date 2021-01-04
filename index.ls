m <<<
	uniqIdVal: 0
	requiredPkgs: []
	cssUnitless:
		animationIterationCount: yes
		borderImageOutset: yes
		borderImageSlice: yes
		borderImageWidth: yes
		boxFlex: yes
		boxFlexGroup: yes
		boxOrdinalGroup: yes
		columnCount: yes
		columns: yes
		flex: yes
		flexGrow: yes
		flexPositive: yes
		flexShrink: yes
		flexNegative: yes
		flexOrder: yes
		gridArea: yes
		gridRow: yes
		gridRowEnd: yes
		gridRowSpan: yes
		gridRowStart: yes
		gridColumn: yes
		gridColumnEnd: yes
		gridColumnSpan: yes
		gridColumnStart: yes
		fontWeight: yes
		lineClamp: yes
		lineHeight: yes
		opacity: yes
		order: yes
		orphans: yes
		tabSize: yes
		widows: yes
		zIndex: yes
		zoom: yes
		fillOpacity: yes
		floodOpacity: yes
		stopOpacity: yes
		strokeDasharray: yes
		strokeDashoffset: yes
		strokeMiterlimit: yes
		strokeOpacity: yes
		strokeWidth: yes

	class: (...clses) ->
		res = []
		for cls in clses
			if Array.isArray cls
				res.push m.class ...cls
			else if cls instanceof Object
				for k, v of cls
					res.push k if v
			else if cls?
				res.push cls
		res.join " "

	style: (...styls) ->
		res = {}
		for styl in styls
			if Array.isArray styl
				styl = m.style ...styl
			if styl instanceof Object
				for k, val of styl
					res[k] = val
					res[k] += \px if not m.cssUnitless[k] and +val
		res

	bind: (obj, thisArg = obj) ->
		for k, val of obj
			if typeof val is \function and val.name isnt /(bound|class) /
				obj[k] = val.bind thisArg
		obj

	comp: (opts,, statics) ->
		comp = ->
			old = null
			vdom = {}
			vdom <<< opts
			vdom <<<
				$$oninit: opts.oninit or ->
				$$oncreate: opts.oncreate or ->
				$$onbeforeupdate: opts.onbeforeupdate or ->
				$$onupdate: opts.onupdate or ->
				$$onbeforeremove: opts.onbeforeremove or ->
				$$onremove: opts.onremove or ->
				oninit: !->
					@{attrs or {}, children or []} = it
					@dom = null
					old :=
						attrs: {...@attrs}
						children: [...@children]
						dom: null
					@$$oninit!
					@$$onbeforeupdate old, yes
				oncreate: !->
					@dom = it.dom
					@$$oncreate!
					@$$onupdate old, yes
				onbeforeupdate: ->
					@{attrs or {}, children or []} = it
					@$$onbeforeupdate old
				onupdate: !->
					@dom = it.dom
					@$$onupdate old
					old :=
						attrs: {...@attrs}
						children: [...@children]
						dom: @dom
				onbeforeremove: ->
					@$$onbeforeremove!
				onremove: !->
					@$$onremove!
			m.bind vdom
		comp <<< statics
		m.bind comp

getCodePoint = (chr) ->
	chr.0.codePointAt 0 .toString 16 .padStart 4 0 .toUpperCase!

[cates, mapChrNames] = await (await fetch \unicode.json)json!
chrs = []
for cate in cates
	cate.2 = ""
	for page in cate.1
		page.cate = cate
		for chr in page
			cate.2 or= getCodePoint chr
			chr.1 .= replace /[~!@#$%^&*()_+]/ (mapChrNames.)
			chr.2 = []
			chr.3 = 0
			chr.4 = no
			chr.5 = ""
			chr.page = page
			chr.cate = cate
			chrs.push chr
	cate.2 and+= " - " + getCodePoint chr

App = m.comp do
	oninit: !->
		@cate = null
		@page = null
		@chr = null
		@g = null
		@w = 21
		@h = 19
		@hoverChr = null
		@hoverChrPopper = null
		@hoverChrTimeout = 0
		@clipboard = []
		@measure =
			* [\origin 7 \#e65]
				[\end 12 \#b4f]
			* [\ascent 3 \#47f]
				[\capline 6 \#b4f]
				[\meanline 8 \#8b7]
				[\baseline 13 \#b4f]
				[\descent 16 \#47f]
		@canDraw = yes
		@clickChr cates.1.1.0.33

	oncreate: !->
		@g = canvas.getContext \2d
		@g.imageSmoothingEnabled = no
		window.oncontextmenu = (.preventDefault!)
		window.onkeydown = @onkeydown

	setCanDraw: (canDraw) !->
		@canDraw = canDraw
		m.redraw!

	chrToD: (chr) ->
		d = ""
		grid = Array @h .fill!map ~> Array @w .fill!
		for pt in chr.2
			grid[pt.1 + 6][pt.0 + 7] = [pt]
		for row in grid
			for col in row
				if col and not col.1
					pt = col.0
					[x, y] = pt
					x2 = x + 7
					vscore = 0
					vline = [col]
					while vcol = row[++x2]
						vscore++
						vline.push vcol
					while vline[* - 1]1
						x2--
						vscore--
						vline.pop!
					y2 = y + 6
					hscore = 0
					hline = [col]
					while hcol = grid[++y2]?[x + 7]
						hscore++
						hline.push hcol
					while hline[* - 1]1
						y2--
						hscore--
						hline.pop!
					if vscore > hscore
						line = vline
						w = x2 - 7 - x
						dd = "M#x,#{y+1}v-1h#{w}v1z"
					else
						line = hline
						h = y2 - 6 - y
						dd = "M#x,#{y}h1v#{h}h-1z"
					dd .= replace /,-/g \-
					d += dd
					for col2 in line
						col2.1 = yes
		d

	repaint: !->
		if @g
			@g.clearRect 0 0 @w, @h
			@g.fillStyle = \#333
		max = -7
		for pt in @chr.2
			max = pt.0 if pt.0 > max
			@g?fillRect pt.0 + 7, 12 - pt.1, 1 1
		unless @chr.4
			@chr.3 = if @chr.2.length => max + 2 else 0
		m.redraw!

	saveFile: (data, type, filename) !->
		blob = new Blob [data] {type}
		el = document.createElement \a
		el.href = URL.createObjectURL blob
		el.download = filename
		el.click!
		URL.revokeObjectURL el.href

	clickPage: (page) !->
		@page = page
		m.redraw!

	clickChr: (chr) !->
		@chr = chr
		@page = chr.page
		@cate = chr.cate
		@repaint!
		m.redraw.sync!
		if @g
			el = catesEl.querySelector \:scope>.active
			el.scrollIntoViewIfNeeded no
		if chr.2.length
			chr.5 = canvas?toDataURL \image/webp

	mouseenterChr: (chr, event) !->
		@hoverChrTimeout = setTimeout !~>
			@hoverChr = chr
			m.redraw.sync!
			@hoverChrPopper = Popper.createPopper event.target, hoverChrPopperEl
		, 200

	mouseleaveChr: (chr, event) !->
		@removeHoverChr!

	removeHoverChr: !->
		clearTimeout @hoverChrTimeout
		if @hoverChrPopper
			@hoverChr = null
			@hoverChrPopper.destroy!
			@hoverChrPopper = null

	onwheelChrs: (event) !->
		if chrsEl.offsetWidth > 400 and chrsEl.offsetHeight > 650
			@removeHoverChr!
			index = @cate.1.indexOf @page
			index += event.deltaY > 0 and 1 or -1
			index %%= @cate.1.length
			@clickPage @cate.1[index]

	onmousedownCanvas: (event) !->
		@onmousemoveCanvas event

	onmousemoveCanvas: (event) !->
		if event.which
			x = event.layerX // 20 - 7
			y = 12 - event.layerY // 20
			pt = @chr.2.find ~>
				it.0 is x and it.1 is y
			switch event.which
			| 1
				unless pt
					@chr.2.push [x, y]
					@repaint!
					@chr.5 = canvas.toDataURL \image/webp
			| 3
				if pt
					@chr.2.splice @chr.2.indexOf(pt), 1
					@repaint!
					if @chr.2.length
						@chr.5 = canvas.toDataURL \image/webp
					else
						@chr.5 = ""

	onmouseupCanvas: (event) !->

	onkeydown: (event) !->
		if @canDraw
			isInput = event.target.matches '
				input[type=text],
				input[type=""],
				input:not([type]),
				input[type=number],
				textarea'
			if isInput
				unless event.repeat
					switch event.code
					| \Escape
						event.target.blur!
			else
				switch event.code
				| \KeyD
					index = chrs.indexOf @chr
					if chr = chrs[index - 1]
						@clickChr chr

				| \KeyF
					index = chrs.indexOf @chr
					if chr = chrs[index + 1]
						@clickChr chr

				| \KeyE
					if @chr.3 > -7
						@chr.3--
					@chr.4 = yes
					m.redraw!

				| \KeyR
					if @chr.3 < 15
						@chr.3++
					@chr.4 = yes
					m.redraw!
				unless event.repeat
					switch event.code
					| \KeyC
						if @chr.2.length or @chr.3
							@clipboard = [[...@chr.2] @chr.3, @chr.4]

					| \KeyV
						for pt in @clipboard.0
							check = @chr.2.some ~> it.0 is pt.0 and it.1 is pt.1
							unless check
								@chr.2.push [...pt]
						@chr.3 = @clipboard.1
						@chr.4 = @clipboard.2
						@repaint!
						if @chr.2.length
							@chr.5 = canvas.toDataURL \image/webp
						else
							@chr.5 = ""

					| \Backspace
						@chr.2.splice 0
						unless @chr.4
							@chr.3 = 0
						@chr.5 = ""
						@repaint!

					| \KeyA
						not= @chr.4
						@repaint!

					| \KeyS
						data = [{}]
						for chr in chrs
							if chr.2.length or chr.3
								item = data.0[chr.0] =
									chr.2.map (.join \,) .join " "
									chr.3
								item.2 = yes if chr.4
						data = JSON.stringify data
						@saveFile data, \application/json \font.json

					| \KeyO
						el = document.createElement \input
						el.type = \file
						el.onchange = (event) !~>
							@setCanDraw no
							data = await el.files.0.text!
							try
								data = JSON.parse data
								lastChr = null
								index = 0
								do anim = !~>
									if chr = chrs[index++]
										if item = data.0[chr.0]
											chr.2 = item.0.split " " .map (.split \, .map ~> +it)
											chr.3 = item.1
											chr.4 = item.2
											@clickChr chr
											lastChr := chr
											requestAnimationFrame anim
										else
											chr.2 = []
											chr.3 = 0
											chr.4 = no
											chr.5 = ""
											if index % 1000
												anim!
											else
												@clickChr chr
												requestAnimationFrame anim
									else
										if lastChr
											@clickChr lastChr
										@repaint!
										@setCanDraw yes
							catch
								alert e.message
								@setCanDraw yes
						el.click!

					| \KeyP
						@setCanDraw no
						advs = {}
						for chr in chrs
							if chr.3
								advs[chr.3] ?= 0
								advs[chr.3]++
						horizAdvXFont = -7
						advs = Object.entries advs
							.sort (a, b) ~> b.1 - a.1
						horizAdvXFont = +advs.0.0
						svg = """
							<?xml version="1.0"?>
							<svg width="100%" height="100%" version="1.1" xmlns="http://www.w3.org/2000/svg">
							<defs>
								<font id="Pixel" horiz-adv-x="#horizAdvXFont">
									<font-face
										units-per-em="1000"
										cap-height="#{13 - @measure.1.1.1}"
										x-height="#{13 - @measure.1.2.1}"
										ascent="#{13 - @measure.1.0.1}"
										descent="#{13 - @measure.1.4.1}"
										unicode-range="U+20-1F9C0"
										font-family="Pixel"
										font-style="Regular"
										panose-1="2 0 0 0 0 0 0 0 0 0"
										designer=""
										designerURL=""
										manufacturer="pixelfont"
										manufacturerURL="https://pixelfont.now.sh"
										license=""
										licenseURL=""
										version=""
										description=""
										copyright=""
										trademark=""
										font-variant="normal"
										font-weight=""
										font-stretch="normal"
										stemv=""
										stemh=""
										slope=""
										underline-position=""
										underline-thickness=""
										strikethrough-position=""
										strikethrough-thickness=""
										overline-position=""
										overline-thickness="">
										<font-face-src>
											<font-face-name name="Pixel"/>
										</font-face-src>
									</font-face>
						"""
						index = 0
						do anim = !~>
							if chr = chrs[index++]
								if chr.2.length or chr.3
									@clickChr chr
									d = @chrToD chr
									unicode = chr.0
									if unicode in <[" ' & < >]>
										unicode = "&\#x#{getCodePoint unicode};"
									glyph = """
										<glyph
											unicode="#unicode"
											d="#d"
									"""
									unless chr.3 is horizAdvXFont
										glyph += """
											\n\thoriz-adv-x="#{chr.3}"
										"""
									glyph += \\n/>
									svg += glyph
									requestAnimationFrame anim
								else
									if index % 1000
										anim!
									else
										@clickChr chr
										requestAnimationFrame anim
							else
								svg += \</font></defs></svg>
								svg .= replace /\  /g \\t
								@saveFile svg,\text/svg \font.svg 
								@setCanDraw yes

	view: ->
		m \.main,
			m \.cates#catesEl,
				cates.map (cate) ~>
					isActive = @cate is cate
					m \.cate,
						class: m.class do
							"active": isActive
						onclick: !~>
							unless isActive
								@cate = cate
								@page = @cate.1.0
						m \.cate-name cate.0
						m \.cate-range cate.2
			m \.pages,
				@cate.1.map (page, i) ~>
					isActive = @page is page
					m \.page,
						class: m.class do
							"active": isActive
						onclick: !~>
							unless isActive
								@clickPage page
						i + 1
			m \.chrs#chrsEl,
				onwheel: @onwheelChrs
				@page.map (chr) ~>
					isActive = @chr is chr
					m \.chr,
						class: m.class do
							"active": isActive
							"chr-hasData": chr.2.length or chr.3
						onmouseenter: !~>
							@mouseenterChr chr, event
						onmouseleave: !~>
							@mouseleaveChr chr, event
						onclick: !~>
							unless isActive
								@clickChr chr
						m \img.chr-img,
							height: @h
							src: chr.5
						m \.chr-chr chr.0
			m \.board,
				m \.canvas,
					m \.grid,
						m \.grid-chr "A#{@chr.0}B"
					m \.measure,
						@measure.0.map (measure) ~>
							m \.measure-hor,
								style:
									left: measure.1 * 20 - 1 + \px
									background: measure.2
						m \.measure-hor,
							style:
								left: (7 + @chr.3) * 20 - 1 + \px
								width: (@chr.4 and 2 or 1) + \px
								background: @measure.0.0.2
						@measure.1.map (measure) ~>
							m \.measure-ver,
								style:
									top: measure.1 * 20 - 1 + \px
									background: measure.2
					m \canvas#canvas,
						width: @w
						height: @h
						onmousedown: @onmousedownCanvas
						onmousemove: @onmousemoveCanvas
						onmouseup: @onmouseupCanvas
			m \.tools,
				m \.props,
					m \.field "Độ rộng ký tự"
					m \.field,
						m \input,
							type: \number
							min: -7
							max: 15
							value: @chr.3
							oninput: (event) !~>
								@chr.3 = event.target.valueAsNumber
								@chr.4 = yes
					m \label.field,
						m \input,
							type: \checkbox
							checked: @chr.4
							oninput: (event) !~>
								not= @chr.4
								@repaint!
						"Độ rộng cố định"
				m \.actions
			if @hoverChr
				m \#hoverChrPopperEl,
					m \.field,
						"@#{@hoverChr.0}& | A#{@hoverChr.0}B"
					m \.field,
						getCodePoint @hoverChr
					m \.field,
						@hoverChr.1
			unless @canDraw
				m \.candraw

m.mount document.body, App
