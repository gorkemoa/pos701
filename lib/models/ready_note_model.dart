class ReadyNote {
  final int noteID;
  final String note;

  ReadyNote({
    required this.noteID,
    required this.note,
  });

  factory ReadyNote.fromJson(Map<String, dynamic> json) {
    return ReadyNote(
      noteID: json['noteID'] as int,
      note: json['note'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteID': noteID,
      'note': note,
    };
  }

  @override
  String toString() {
    return 'ReadyNote{noteID: $noteID, note: $note}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadyNote &&
        other.noteID == noteID &&
        other.note == note;
  }

  @override
  int get hashCode => noteID.hashCode ^ note.hashCode;
}

class ReadyNotesResponse {
  final List<ReadyNote> notes;

  ReadyNotesResponse({
    required this.notes,
  });

  factory ReadyNotesResponse.fromJson(Map<String, dynamic> json) {
    return ReadyNotesResponse(
      notes: (json['notes'] as List)
          .map((noteJson) => ReadyNote.fromJson(noteJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notes': notes.map((note) => note.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'ReadyNotesResponse{notes: $notes}';
  }
}
