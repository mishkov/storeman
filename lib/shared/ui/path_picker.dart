import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class PathPicker extends StatefulWidget {
  const PathPicker({
    super.key,
    required this.name,
    this.defaultPath = '',
    required this.onChanged,
  });

  final String name;
  final String defaultPath;
  final void Function(String path) onChanged;

  @override
  State<PathPicker> createState() => _PathPickerState();
}

class _PathPickerState extends State<PathPicker> {
  late final _directoryPathController = TextEditingController(
    text: widget.defaultPath,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _directoryPathController,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              // TODO: localize the message.
              labelText: widget.name,
              enabledBorder: OutlineInputBorder(),
              errorBorder: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(),
              disabledBorder: OutlineInputBorder(),
              focusedErrorBorder: OutlineInputBorder(),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          onPressed: () async {
            final selectedDirectory =
                await FilePicker.platform.getDirectoryPath();

            if (selectedDirectory == null) {
              return;
            }

            _directoryPathController.text = selectedDirectory;
            widget.onChanged(selectedDirectory);
          },
          icon: const Icon(Icons.folder_open_rounded),
        ),
      ],
    );
  }
}
