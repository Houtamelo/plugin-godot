@tool extends Control
## A button that logs the user in to the Rivet using Rivet CLI.

@onready var LogInButton: Button = %LogInButton
@onready var CloudTokenTextEdit: TextEdit = %CloudTokenTextEdit
@onready var NamespaceTokenTextEdit: TextEdit = %NamespaceTokenTextEdit

func _ready():
	LogInButton.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	%LogInButton.disabled = true
	var result := await RivetDevtools.get_plugin().cli.run_command([
		"--api-endpoint",
		"https://api.staging2.gameinc.io",
		"sidekick",
		"get-link",
	])
	if result.exit_code == result.ExitCode.SUCCESS and result.output.has("Ok"):
		var data: Dictionary = result.output["Ok"]

		# Now that we have the link, open it in the user's browser
		OS.shell_open(data["device_link_url"])
		
		owner.change_current_screen(owner.Screen.Loading)

		# Long-poll the Rivet API until the user has logged in
		result = await RivetDevtools.get_plugin().cli.run_command([
			"--api-endpoint",
			"https://api.staging2.gameinc.io",
			"sidekick",
			"wait-for-login",
			"--device-link-token",
			data["device_link_token"],
		])

		if result.exit_code == result.ExitCode.SUCCESS:
			RivetDevtools.get_plugin().cloud_token = CloudTokenTextEdit.text
			RivetDevtools.get_plugin().namespace_token = NamespaceTokenTextEdit.text

			owner.change_current_screen(owner.Screen.Settings)

	LogInButton.disabled = false
