xray_tracing_enabled = true
vpc_config = {
  subnet_ids        = ["32b32baa-551b-49ba-a848-33db3bcac03c", "77e41782-96e0-4010-8310-07c058f3f93c"]
  security_group_id = ["dbf42868-3864-41c1-afe1-e9b6b925054f"]
}
dead_letter_arn = "arn:aws:sqs:29ab394a-f3e8-4a59-bed8-9d3fe634ae78"
file_system_config = {
  arn       = "af60424e-70bb-4c07-964f-120fb5533f5c"
  read_only = false
}
