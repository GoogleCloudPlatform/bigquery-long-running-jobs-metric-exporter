/*
 Copyright 2023 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

variable "workflow_deployment_project" {

  type        = string
  description = "The Google Cloud Project to deploy the Workflow in"

}

variable "workflow_deployment_region" {
  type        = string
  description = "The region to deploy the Workflow to"
  default     = "europe-west2"
}

variable "monitored_projects_and_regions" {
  description = "The projects and regions to monitor for long running jobs"
  type        = map(list(string))
}

variable "master_query_project" {
  description = "The project to run all queries from"
  default     = ""
}

variable "master_metrics_project" {
  description = "The project to store all metrics in"
  default     = ""
}

variable "long_running_job_polling_period" {
  description = "The period in which the Workflow should execute in Cron format"
  default     = "*/5 * * * *"
}

variable "job_duration_alert_threshold_minutes" {
  description = "How long should jobs be running for before the alert is triggered (minutes)"
  type        = number
  default     = 30
}
