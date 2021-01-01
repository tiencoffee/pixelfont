ranges = await (await fetch \https://cdn.jsdelivr.net/gh/radiovisual/unicode-range-json/unicode-ranges.json)json!
ranges.splice -2
glyphs = [til 0x1f9ff]map (i) ~>
	index: i
	chr: String.fromCodePoint i
	horizAdvX: 0
	d: void
App =
	oninit: !->
		for k, val of @
			if typeof val is \function
				@[k] = val.bind @
		@range = ranges.0
		@glyphs = []

	view: ->
		m \.main,
			m \.pages,
				ranges.map (range) ~>
					m \.page,
						onclick: !~>
							@range = range
							@glyphs = glyphs.slice range.range.0, range.range.1 + 1
						m \.page-name range.category
						m \.page-range range.hexrange.join " - "
			m \.glyphs,
				@glyphs.map (glyph) ~>
					m \.glyph,
						title: unicharadata.name glyph.chr
						m \.glyph-chr glyph.chr
			m \.view 2

m.mount document.body, App

data = [[]]
data.1 =
	"~": "CJK IDEOGRAPH-"
	"!": "CJK IDEOGRAPH EXTENSION A-"
	"@": "HANGUL SYLLABLE-"
	"#": "PRIVATE USE-"
	"$": "YI SYLLABLE "
	"%": "CUNEIFORM SIGN "
	"^": "EGYPTIAN HIEROGLYPH "
	"&": "LOW SURROGATE-D"
	"*": "NON PRIVATE USE HIGH SURROGATE-D"
	"(": "LATIN SMALL LETTER "
	")": "CJK COMPATIBILITY IDEOGRAPH-F"
	"_": "MATHEMATICAL SANS-SERIF BOLD "
	"+": "PRIVATE USE HIGH SURROGATE-D"

for range in ranges
	uni = [range.category, []]
	data.0.push uni
	for i til Math.ceil (range.range.1 - range.range.0 + 1) / 64
		startCp = range.range.0 + i * 64
		page = uni.1[i] = []
		for cp from startCp til startCp + 64
			if cp <= range.range.1
				chr = String.fromCodePoint cp
				if name = unicharadata.name chr
					for k, val of data.1
						if name.includes val
							name .= replace val, k
							break
					page.push [chr, name]
console.log JSON.stringify data
