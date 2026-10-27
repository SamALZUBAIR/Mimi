extends Control

const BG_PATH := "res://assets/checkpoint-scene.svg"
const VISITOR_PATH := "res://assets/visitor-sprite.svg"

var day_number := 1
var visitor_number := 0
var silver := 12
var warnings := 0
var allowed_count := 0
var refused_count := 0
var investigated_count := 0
var current_visitor: Dictionary = {}

var visitor_data: Array[Dictionary] = [
	{"name":"سليم ناصر","age":31,"job":"عامل شحن","permit":"A-1842","purpose":"تسليم صندوق قطع غيار","risk":false,"detail":"البيانات متطابقة، لكن ختم الدخول باهت."},
	{"name":"مها فؤاد","age":27,"job":"ممرضة","permit":"C-0931","purpose":"زيارة قريب محتجز","risk":false,"detail":"تاريخ التصريح صحيح وصورة الهوية واضحة."},
	{"name":"رائد منصور","age":46,"job":"تاجر","permit":"B-7710","purpose":"نقل بضائع إلى المستودع","risk":true,"detail":"رقم التصريح لا يطابق الرقم المسجل في دفتر اليوم."},
	{"name":"طفل مجهول الاسم","age":12,"job":"غير محدد","permit":"لا يوجد","purpose":"البحث عن والده","risk":true,"detail":"لا يحمل وثيقة، ويقول إن موظفًا أعطاه هذا العنوان."},
	{"name":"نجيب عارف","age":39,"job":"موظف حكومي","permit":"A-2048","purpose":"مراجعة إدارية عاجلة","risk":false,"detail":"كل الأوراق سليمة، لكن صاحب الطلب يبدو متوترًا."},
	{"name":"هدى سالم","age":34,"job":"خياطة","permit":"D-5022","purpose":"تسليم حقيبة إلى أحد العاملين","risk":true,"detail":"توجد اختلافات في توقيع الجهة المصدرة."}
]

var background: TextureRect
var portrait: TextureRect
var header_label: Label
var silver_label: Label
var status_label: Label
var name_label: Label
var age_job_label: Label
var permit_label: Label
var purpose_label: Label
var detail_label: Label
var result_label: Label
var allow_button: Button
var refuse_button: Button
var inspect_button: Button
var next_button: Button
var document_panel: PanelContainer
var decisions: HBoxContainer

func _ready() -> void:
	_build_interface()
	_show_visitor()

func _build_interface() -> void:
	background = TextureRect.new()
	background.texture = load(BG_PATH)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var tint := ColorRect.new()
	tint.color = Color(0.025, 0.04, 0.045, 0.42)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)

	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 18
	page.offset_top = 14
	page.offset_right = -18
	page.offset_bottom = -14
	page.add_theme_constant_override("separation", 10)
	add_child(page)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.075, 0.075, 0.96), Color(0.72, 0.56, 0.29)))
	header.custom_minimum_size.y = 48
	page.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 16)
	header.add_child(header_row)
	header_label = _label("بوابة الرماد  |  سجل الحدود", 22, Color(0.93, 0.79, 0.49))
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_label)
	silver_label = _label("", 17, Color(0.95, 0.88, 0.68))
	header_row.add_child(silver_label)

	var main_row := HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 12)
	page.add_child(main_row)

	var visitor_panel := PanelContainer.new()
	visitor_panel.custom_minimum_size = Vector2(200, 0)
	visitor_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visitor_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.08, 0.08, 0.93), Color(0.36, 0.43, 0.39)))
	main_row.add_child(visitor_panel)
	var visitor_box := VBoxContainer.new()
	visitor_box.alignment = BoxContainer.ALIGNMENT_CENTER
	visitor_box.add_theme_constant_override("separation", 8)
	visitor_panel.add_child(visitor_box)
	var visitor_title := _label("الزائر الحالي", 18, Color(0.86, 0.77, 0.56))
	visitor_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visitor_box.add_child(visitor_title)
	portrait = TextureRect.new()
	portrait.texture = load(VISITOR_PATH)
	portrait.custom_minimum_size = Vector2(144, 192)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	visitor_box.add_child(portrait)
	name_label = _label("", 20, Color(0.97, 0.91, 0.77))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visitor_box.add_child(name_label)
	age_job_label = _label("", 14, Color(0.72, 0.76, 0.71))
	age_job_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visitor_box.add_child(age_job_label)

	document_panel = PanelContainer.new()
	document_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	document_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	document_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.78, 0.73, 0.59, 0.98), Color(0.22, 0.25, 0.21)))
	main_row.add_child(document_panel)
	var doc_box := VBoxContainer.new()
	doc_box.add_theme_constant_override("separation", 9)
	document_panel.add_child(doc_box)
	var doc_title := _label("وثيقة العبور", 23, Color(0.16, 0.20, 0.17))
	doc_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	doc_box.add_child(doc_title)
	var separator := HSeparator.new()
	doc_box.add_child(separator)
	permit_label = _doc_label()
	doc_box.add_child(permit_label)
	purpose_label = _doc_label()
	doc_box.add_child(purpose_label)
	detail_label = _doc_label()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	doc_box.add_child(detail_label)
	var warning := _label("افحص المعلومات قبل اتخاذ القرار.", 14, Color(0.35, 0.29, 0.19))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	doc_box.add_child(warning)

	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.06, 0.06, 0.96), Color(0.39, 0.43, 0.36)))
	page.add_child(footer)
	var footer_box := VBoxContainer.new()
	footer_box.add_theme_constant_override("separation", 8)
	footer.add_child(footer_box)
	status_label = _label("", 15, Color(0.88, 0.84, 0.7))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer_box.add_child(status_label)
	result_label = _label("", 15, Color(0.98, 0.79, 0.43))
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer_box.add_child(result_label)
	decisions = HBoxContainer.new()
	decisions.add_theme_constant_override("separation", 8)
	footer_box.add_child(decisions)
	inspect_button = _button("فحص إضافي", Color(0.31, 0.39, 0.34))
	inspect_button.pressed.connect(_inspect)
	decisions.add_child(inspect_button)
	refuse_button = _button("رفض العبور", Color(0.48, 0.22, 0.19))
	refuse_button.pressed.connect(_decide.bind(false))
	decisions.add_child(refuse_button)
	allow_button = _button("السماح بالعبور", Color(0.24, 0.39, 0.29))
	allow_button.pressed.connect(_decide.bind(true))
	decisions.add_child(allow_button)
	next_button = _button("الزائر التالي", Color(0.42, 0.32, 0.17))
	next_button.pressed.connect(_on_next_pressed)
	next_button.visible = false
	decisions.add_child(next_button)

func _show_visitor() -> void:
	if visitor_number >= visitor_data.size():
		_end_day()
		return
	current_visitor = visitor_data[visitor_number]
	header_label.text = "بوابة الرماد  |  اليوم %d  |  زائر %d/%d" % [day_number, visitor_number + 1, visitor_data.size()]
	silver_label.text = "الرصيد: %d فضة   |   إنذارات: %d" % [silver, warnings]
	name_label.text = str(current_visitor.name)
	age_job_label.text = "%s سنة  •  %s" % [current_visitor.age, current_visitor.job]
	permit_label.text = "رقم التصريح:  %s" % current_visitor.permit
	purpose_label.text = "سبب الزيارة:  %s" % current_visitor.purpose
	detail_label.text = "ملاحظات الموظف:\n%s" % current_visitor.detail
	status_label.text = "اقرأ الوثيقة وقارن بياناتها. بعض الحالات تحتاج إلى فحص إضافي."
	result_label.text = ""
	allow_button.disabled = false
	refuse_button.disabled = false
	inspect_button.disabled = false
	next_button.visible = false
	allow_button.visible = true
	refuse_button.visible = true
	inspect_button.visible = true

func _inspect() -> void:
	investigated_count += 1
	if bool(current_visitor.risk):
		detail_label.text += "\n\nنتيجة الفحص: ظهرت مخالفة محتملة. راجع رقم التصريح والتوقيع."
		status_label.text = "الفحص كشف تناقضًا يستحق التحقيق."
	else:
		detail_label.text += "\n\nنتيجة الفحص: لا توجد مخالفة واضحة في السجل."
		status_label.text = "الفحص لم يكشف مشكلة مؤكدة."
	inspect_button.disabled = true

func _decide(allow: bool) -> void:
	var risk := bool(current_visitor.risk)
	var correct := (not allow and risk) or (allow and not risk)
	if correct:
		silver += 1
		result_label.text = "قرار صحيح. حصلت على فضة واحدة."
		status_label.text = "تم تسجيل القرار في دفتر المناوبة."
	else:
		warnings += 1
		silver = maxi(0, silver - 2)
		result_label.text = "قرار خاطئ! خصم فضتين وتسجيل إنذار."
		status_label.text = "القرارات الخاطئة قد تؤثر على وظيفتك وراتبك."
	if allow:
		allowed_count += 1
	else:
		refused_count += 1
	allow_button.disabled = true
	refuse_button.disabled = true
	inspect_button.disabled = true
	next_button.visible = true
	silver_label.text = "الرصيد: %d فضة   |   إنذارات: %d" % [silver, warnings]

func _next_visitor() -> void:
	visitor_number += 1
	_show_visitor()

func _end_day() -> void:
	header_label.text = "انتهت المناوبة  |  اليوم %d" % day_number
	name_label.text = "ملخص اليوم"
	age_job_label.text = "تمت معالجة جميع الحالات"
	permit_label.text = "تم السماح: %d" % allowed_count
	purpose_label.text = "تم الرفض: %d" % refused_count
	detail_label.text = "عمليات الفحص الإضافي: %d\nالإنذارات: %d\nالرصيد الحالي: %d فضة" % [investigated_count, warnings, silver]
	status_label.text = "انتهى يوم العمل. يمكنك بدء مناوبة جديدة."
	result_label.text = "ستتغير الحالات في الأيام التالية مع تقدم الحملة."
	allow_button.visible = false
	refuse_button.visible = false
	inspect_button.visible = false
	next_button.text = "بدء اليوم التالي"
	next_button.visible = true
	next_button.disabled = false


func _on_next_pressed() -> void:
	if visitor_number >= visitor_data.size():
		_start_next_day()
	else:
		_next_visitor()

func _start_next_day() -> void:
	day_number += 1
	visitor_number = 0
	allowed_count = 0
	refused_count = 0
	investigated_count = 0
	next_button.text = "الزائر التالي"
	_show_visitor()

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.layout_direction = Control.LAYOUT_DIRECTION_RTL
	return label

func _doc_label() -> Label:
	var label := _label("", 18, Color(0.19, 0.22, 0.18))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return label

func _button(value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.96, 0.92, 0.81))
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = color.lightened(0.2)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	return button

func _panel_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
