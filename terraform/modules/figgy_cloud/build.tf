data "archive_file" "figgy" {
  source_dir  = "lambdas/"
  output_path = "figgy.zip"
  type        = "zip"
  depends_on = [time_sleep.wait_60_seconds]
}

resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"
}