extends Node

signal heard(transcripts: Array)
signal unavailable(message: String)
signal devices_updated(devices: Array, message: String)
signal microphone_check(active: bool, message: String)

const LISTEN_LIMIT := 14.0
const TRANSCRIBE_LIMIT := 12.0
const MICROPHONE_CHECK_SECONDS := 3.0
const WEB_RADIO := """
window.backyardRadioSpeech = {
    session: null,
    micCheck: null,
    cancelMicCheck() {
        const check = this.micCheck;
        if (!check) return;
        this.micCheck = null;
        if (check.frame !== undefined) cancelAnimationFrame(check.frame);
        this.releaseTracks(check);
        if (check.context) check.context.close().catch(() => {});
    },
    async checkMic(deviceId, update, seconds) {
        const media = navigator.mediaDevices;
        const AudioContext = window.AudioContext || window.webkitAudioContext;
        if (!media?.getUserMedia || !AudioContext) {
            update(false, "Chrome cannot test the microphone here.");
            return;
        }
        const check = {};
        this.micCheck = check;
        try {
            check.context = new AudioContext();
            const resumed = check.context.resume().then(() => true, () => false);
            const audio = deviceId ? {deviceId: {exact: deviceId}} : true;
            check.stream = await media.getUserMedia({audio});
            if (this.micCheck !== check) {
                this.releaseTracks(check);
                return;
            }
            if (!await resumed) throw new Error("audio context unavailable");
            if (this.micCheck !== check) return;
            const analyser = check.context.createAnalyser();
            check.context.createMediaStreamSource(check.stream).connect(analyser);
            const samples = new Float32Array(analyser.fftSize);
            const end = performance.now() + seconds * 1000;
            let peak = 0;
            update(true, "Speak normally for three seconds…");
            const measure = now => {
                analyser.getFloatTimeDomainData(samples);
                let sum = 0;
                for (const sample of samples) sum += sample * sample;
                peak = Math.max(peak, Math.sqrt(sum / samples.length));
                if (now < end) {
                    check.frame = requestAnimationFrame(measure);
                    return;
                }
                this.cancelMicCheck();
                let message = peak < 0.005 ? "No microphone signal detected." :
                    peak < 0.018 ? "Microphone signal is very quiet." : "Microphone signal looks good.";
                if (peak >= 0.005 && !(window.SpeechRecognition || window.webkitSpeechRecognition)) {
                    message = "Mic works. Chrome speech recognition is unavailable.";
                }
                update(false, message);
            };
            check.frame = requestAnimationFrame(measure);
        } catch (error) {
            if (this.micCheck !== check) return;
            this.cancelMicCheck();
            const message = error.name === "NotAllowedError" ? "Microphone permission was denied." :
                error.name === "OverconstrainedError" ? "Selected mic is unavailable." :
                "Chrome could not open the microphone.";
            update(false, message);
        }
    },
    releaseTracks(session) {
        if (session.stream) {
            for (const track of session.stream.getTracks()) track.stop();
            session.stream = null;
        }
    },
    async devices(requestAccess, done) {
        const media = navigator.mediaDevices;
        if (!media || !media.enumerateDevices) {
            done("[]", "Chrome cannot list microphones here.");
            return;
        }
        let stream;
        try {
            if (requestAccess) stream = await media.getUserMedia({audio: true});
            const inputs = (await media.enumerateDevices()).filter(device =>
                device.kind === "audioinput" && device.deviceId &&
                device.deviceId !== "default" && device.deviceId !== "communications");
            done(JSON.stringify(inputs.map((device, index) => ({
                id: device.deviceId, label: device.label || "Microphone " + (index + 1)
            }))), inputs.length ? "" : "Choose Find mics and allow access in Chrome.");
        } catch {
            done("[]", "Chrome microphone access is unavailable.");
        } finally {
            if (stream) for (const track of stream.getTracks()) track.stop();
        }
    },
    start(deviceId, done) {
        const Speech = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!Speech) return false;
        const recognition = new Speech();
        const session = {recognition, done, started: false, stream: null};
        const phrases = [];
        let error = "";
        this.session = session;
        recognition.lang = "en-US";
        recognition.continuous = true;
        recognition.maxAlternatives = 3;
        recognition.onresult = event => {
            for (let i = event.resultIndex; i < event.results.length; i++) {
                const result = event.results[i];
                if (result.isFinal) phrases[i] = Array.from(result, alternative => alternative.transcript.trim());
            }
        };
        recognition.onerror = event => {
            const messages = {
                "not-allowed": "Chrome denied microphone access.",
                "audio-capture": "Chrome could not capture from this microphone.",
                "network": "Chrome speech recognition could not reach its service.",
                "no-speech": "Chrome received no speech."
            };
            error = (messages[event.error] || "Chrome speech recognition is unavailable.") + " Press T to type.";
        };
        recognition.onend = () => {
            this.releaseTracks(session);
            if (this.session !== session) return;
            this.session = null;
            const segments = phrases.filter(phrase => phrase?.length);
            const primary = segments.map(choices => choices[0]);
            const transcripts = [primary.join(" ")];
            for (const [index, choices] of segments.entries()) {
                for (const choice of choices.slice(1)) {
                    const alternative = primary.slice();
                    alternative[index] = choice;
                    transcripts.push(alternative.join(" "));
                }
            }
            done(JSON.stringify(transcripts), error);
        };
        if (!deviceId) {
            try { recognition.start(); session.started = true; return true; }
            catch { this.session = null; return false; }
        }
        if (!navigator.mediaDevices?.getUserMedia) { this.session = null; return false; }
        navigator.mediaDevices.getUserMedia({audio: {deviceId: {exact: deviceId}}}).then(stream => {
            session.stream = stream;
            if (this.session !== session) { this.releaseTracks(session); return; }
            recognition.start(stream.getAudioTracks()[0]);
            session.started = true;
        }).catch(() => {
            this.releaseTracks(session);
            if (this.session !== session) return;
            this.session = null;
            done("[]", "Selected mic unavailable. Choose another in Audio Settings.");
        });
        return true;
    },
    stop() {
        const session = this.session;
        if (!session) return;
        if (session.started) {
            session.recognition.stop();
        } else {
            this.session = null;
            this.releaseTracks(session);
            session.done("[]", "Microphone was still opening. Hold V a little longer.");
        }
    },
    cancel() {
        const session = this.session;
        this.session = null;
        if (!session) return;
        this.releaseTracks(session);
        if (session.started) session.recognition.abort();
    },
};
"""

var listening := false
var transcribing := false
var time_left := 0.0
var microphone: AudioStreamPlayer
var recorder: AudioEffectRecord
var web: JavaScriptObject
var web_callback: JavaScriptObject
var devices_callback: JavaScriptObject
var mic_check_callback: JavaScriptObject
var mic_check_active := false
var mic_check_generation := 0
var web_result: Array = []
var child_pid := -1
var recording_path := ""
var result_path := ""
var input_device := ""
var last_transcript := ""

func make_web() -> void:
	if web != null:
		return
	JavaScriptBridge.eval(WEB_RADIO, true)
	web = JavaScriptBridge.get_interface("backyardRadioSpeech")
	web_callback = JavaScriptBridge.create_callback(receive_web)
	devices_callback = JavaScriptBridge.create_callback(receive_devices)
	mic_check_callback = JavaScriptBridge.create_callback(receive_microphone_check)

func find_devices(request_access := false) -> void:
	if OS.has_feature("web"):
		make_web()
		if web != null:
			web.devices(request_access, devices_callback)
			return
	elif OS.has_feature("windows"):
		var devices: Array = []
		for device in AudioServer.get_input_device_list():
			if device != "Default":
				devices.append({"id": device, "label": device})
		devices_updated.emit(devices, "" if not devices.is_empty() else "No separate input devices found.")
		return
	devices_updated.emit([], "Microphone selection is unavailable here.")

func receive_devices(args: Array) -> void:
	var devices: Variant = JSON.parse_string(String(args[0]))
	devices_updated.emit(devices if devices is Array else [], String(args[1]))

func test_microphone() -> void:
	if mic_check_active or listening or transcribing:
		return
	mic_check_active = true
	mic_check_generation += 1
	microphone_check.emit(true, "Opening microphone…")
	if OS.has_feature("web"):
		make_web()
		if web != null:
			web.checkMic(input_device, mic_check_callback, MICROPHONE_CHECK_SECONDS)
		else:
			report_microphone_check(false, "Chrome cannot test the microphone here.")
	elif OS.has_feature("windows"):
		if not input_device.is_empty() and input_device not in AudioServer.get_input_device_list():
			report_microphone_check(false, "Selected mic is unavailable.")
			return
		AudioServer.input_device = "Default" if input_device.is_empty() else input_device
		if microphone == null:
			make_microphone()
		microphone.process_mode = Node.PROCESS_MODE_ALWAYS
		recorder.set_recording_active(true)
		microphone.play()
		microphone_check.emit(true, "Speak normally for three seconds…")
		var timer := get_tree().create_timer(MICROPHONE_CHECK_SECONDS)
		timer.timeout.connect(finish_microphone_check.bind(mic_check_generation))
	else:
		report_microphone_check(false, "Microphone testing is unavailable here.")

func receive_microphone_check(args: Array) -> void:
	if mic_check_active:
		report_microphone_check(bool(args[0]), String(args[1]))

func report_microphone_check(active: bool, message: String) -> void:
	mic_check_active = active
	microphone_check.emit(active, message)

func finish_microphone_check(generation: int) -> void:
	if not mic_check_active or generation != mic_check_generation:
		return
	stop_microphone_check_capture()
	var recording := recorder.get_recording()
	report_microphone_check(false, microphone_level_message(recording))

func stop_microphone_check_capture() -> void:
	microphone.stop()
	recorder.set_recording_active(false)
	microphone.process_mode = Node.PROCESS_MODE_INHERIT

func cancel_microphone_check() -> void:
	if not mic_check_active:
		return
	mic_check_active = false
	if OS.has_feature("web") and web != null:
		web.cancelMicCheck()
	elif microphone:
		stop_microphone_check_capture()
	microphone_check.emit(false, "Microphone test stopped.")

static func microphone_level_message(recording: AudioStreamWAV) -> String:
	if recording == null or recording.get_length() < 0.15:
		return "No audio reached the game. Check the selected mic."
	var pcm := recording.data
	var block_size := roundi(recording.mix_rate * 0.05) * (4 if recording.stereo else 2)
	var peak := 0.0
	for offset in range(0, pcm.size() - block_size + 1, block_size):
		var energy := 0.0
		var count := 0
		for sample in range(offset, offset + block_size - 1, 2):
			var amplitude := float(pcm.decode_s16(sample)) / 32768.0
			energy += amplitude * amplitude
			count += 1
		peak = maxf(peak, sqrt(energy / count))
	if peak < 0.005:
		return "No microphone signal detected."
	if peak < 0.018:
		return "Microphone signal is very quiet."
	return "Microphone signal looks good."

func begin() -> void:
	if mic_check_active or listening or transcribing:
		return
	last_transcript = ""
	DisplayServer.tts_stop()
	if OS.has_feature("web"):
		make_web()
		web_result.clear()
		if web == null or not web.start(input_device, web_callback):
			unavailable.emit("Chrome speech unavailable. Press T to type.")
			return
	elif OS.has_feature("windows"):
		if not input_device.is_empty() and input_device not in AudioServer.get_input_device_list():
			unavailable.emit("Selected mic unavailable. Choose another in Audio Settings.")
			return
		AudioServer.input_device = "Default" if input_device.is_empty() else input_device
		if microphone == null:
			make_microphone()
		recorder.set_recording_active(true)
		microphone.play()
	else:
		unavailable.emit("Voice unavailable. Press T to type.")
		return
	listening = true
	time_left = LISTEN_LIMIT

func end() -> void:
	if not listening:
		return
	listening = false
	transcribing = true
	time_left = TRANSCRIBE_LIMIT
	if OS.has_feature("web"):
		if web_result.is_empty():
			web.stop()
		else:
			finish_web(web_result)
	elif OS.has_feature("windows"):
		microphone.stop()
		recorder.set_recording_active(false)
		var recording := recorder.get_recording()
		if recording == null or recording.get_length() < 0.15:
			finish([], "No speech heard. Try V again or press T to type.")
		else:
			transcribe_windows(recording)

func receive_web(args: Array) -> void:
	if listening:
		web_result = args
	elif transcribing:
		finish_web(args)

func finish_web(args: Array) -> void:
	var transcripts: Variant = JSON.parse_string(String(args[0]))
	finish(transcripts if transcripts is Array else [], String(args[1]))

func make_microphone() -> void:
	var bus := AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus, "Radio Mic")
	AudioServer.set_bus_volume_db(bus, -80.0)
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(bus, recorder)
	microphone = AudioStreamPlayer.new()
	microphone.stream = AudioStreamMicrophone.new()
	microphone.bus = &"Radio Mic"
	add_child(microphone)

func transcribe_windows(recording: AudioStreamWAV) -> void:
	var stem := "user://radio-%d-%d" % [OS.get_process_id(), Time.get_ticks_msec()]
	recording_path = ProjectSettings.globalize_path(stem + ".wav")
	result_path = ProjectSettings.globalize_path(stem + ".txt")
	if recording.save_to_wav(recording_path) != OK:
		finish([], "Could not capture audio. Press T to type.")
		return
	var script := """
$ErrorActionPreference = 'Stop'
$wave = '%s'
$out = '%s'
$transcripts = @()
$failure = ""
try {
    Add-Type -AssemblyName System.Speech
    $engine = [System.Speech.Recognition.SpeechRecognitionEngine]::new([CultureInfo]::GetCultureInfo('en-US'))
    try {
        $commands = [System.Speech.Recognition.Choices]::new([string[]] @(
            'fire for effect', 'check fire', 'check fire check fire'
        ))
        $builder = [System.Speech.Recognition.GrammarBuilder]::new($commands)
        $builder.Culture = [CultureInfo]::GetCultureInfo('en-US')
        $commandGrammar = [System.Speech.Recognition.Grammar]::new($builder)
        $engine.LoadGrammar($commandGrammar)
        $engine.LoadGrammar([System.Speech.Recognition.DictationGrammar]::new())
        $engine.MaxAlternates = 3
        $engine.EndSilenceTimeout = [TimeSpan]::FromSeconds(2)
        $engine.EndSilenceTimeoutAmbiguous = [TimeSpan]::FromSeconds(2)
        $engine.SetInputToWaveFile($wave)
        $result = $engine.Recognize()
        if ($result) {
            $transcripts = @($result.Text) + @($result.Alternates | ForEach-Object Text) |
                Select-Object -Unique
        }
    } finally { $engine.Dispose() }
} catch {
    $transcripts = @()
    $failure = "Windows speech recognition could not process the recording. Press T to type."
}
$json = ConvertTo-Json -InputObject @{ transcripts = @($transcripts); error = $failure } -Compress
[IO.File]::WriteAllText($out, $json, [Text.UTF8Encoding]::new($false))
""" % [recording_path.replace("'", "''"), result_path.replace("'", "''")]
	var powershell := OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
	var encoded := Marshalls.raw_to_base64(script.to_utf16_buffer())
	child_pid = OS.create_process(powershell, ["-NoLogo", "-NoProfile", "-NonInteractive", "-EncodedCommand", encoded])
	if child_pid < 0:
		finish([], "Windows speech unavailable. Press T to type.")

func finish(transcripts: Array, error: String) -> void:
	transcribing = false
	web_result.clear()
	remove_recording()
	last_transcript = "" if transcripts.is_empty() else String(transcripts.front()).strip_edges()
	if not last_transcript.is_empty():
		heard.emit(transcripts)
	else:
		unavailable.emit(error if not error.is_empty() else "No speech heard. Try V again or press T to type.")

func remove_recording() -> void:
	if not recording_path.is_empty() and FileAccess.file_exists(recording_path):
		DirAccess.remove_absolute(recording_path)
	if not result_path.is_empty() and FileAccess.file_exists(result_path):
		DirAccess.remove_absolute(result_path)
	recording_path = ""
	result_path = ""

func cancel() -> void:
	last_transcript = ""
	listening = false
	transcribing = false
	web_result.clear()
	if web != null:
		web.cancel()
	if microphone:
		microphone.stop()
		recorder.set_recording_active(false)
	if child_pid > 0:
		if OS.is_process_running(child_pid):
			OS.kill(child_pid)
		child_pid = -1
	remove_recording()

func _exit_tree() -> void:
	cancel_microphone_check()
	cancel()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and (listening or transcribing):
		cancel()

func _process(delta: float) -> void:
	if not listening and not transcribing:
		return
	time_left -= delta
	if child_pid > 0 and not OS.is_process_running(child_pid):
		child_pid = -1
		var response: Variant = JSON.parse_string(FileAccess.get_file_as_string(result_path)) if FileAccess.file_exists(result_path) else null
		if response is Dictionary and response.get("transcripts") is Array:
			finish(response.transcripts, String(response.get("error", "")))
		else:
			finish([], "Windows speech recognition did not return a result. Press T to type.")
	elif time_left <= 0.0:
		if listening:
			end()
		else:
			cancel()
			unavailable.emit("Radio timed out. Press T to type.")
