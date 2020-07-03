data "archive_file" "figgy" {
  source_dir = "lambdas/"
  output_path = "figgy.zip"
  type = "zip"
}