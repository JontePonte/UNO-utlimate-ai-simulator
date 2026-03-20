extends Button # (Ändra till LinkButton om du valde det som root)

# Genom att exportera variabeln kan du faktiskt ändra länken 
# direkt i Inspektorn utan att öppna skriptet!
@export var form_url: String = "https://docs.google.com/forms/d/e/1FAIpQLSeZgdg--MArC-Yq-vorgWQeb4nUZjDPLSrp5pwGxabbnxeobQ/viewform?usp=sharing&ouid=103639391687466810165"

func _ready() -> void:
	if GlobalInputs.SHOW_REPORT_BUG_BUTTON:
		show()
	else:
		hide()
	# Koppla knapptrycket till funktionen
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# OS.shell_open säger åt datorn att öppna länken i standardwebbläsaren
	if form_url != "":
		OS.shell_open(form_url)
	else:
		print("Varning: Ingen länk är inlagd i BugReportButton!")
