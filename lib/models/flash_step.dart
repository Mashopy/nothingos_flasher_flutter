class FlashStep {
  final String partition;
  final String file;
  final bool required;

  FlashStep(this.partition, this.file, {this.required = true});
}

class LogicalStep {
  final String partition;
  LogicalStep(this.partition);
}

