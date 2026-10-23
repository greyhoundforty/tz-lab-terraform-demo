output "student_access_file" {
  description = "CSV of each student virtual server, its floating IP, and its Guacamole password."
  value       = local_file.student_access.filename
}
