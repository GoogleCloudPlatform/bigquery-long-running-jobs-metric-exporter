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


resource "google_service_account" "long_running_jobs_workflow_invoker" {
  account_id   = "long-running-jobs-wf-invoker"
  display_name = "Service Account for Cloud Scheduler to invoke the long-running-jobs Cloud Workflow"
  project      = var.workflow_deployment_project
}

resource "google_project_iam_member" "long_running_jobs_workflow_invoker" {
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.long_running_jobs_workflow_invoker.email}"
  project = var.workflow_deployment_project
}

resource "google_project_service" "cloud_scheduler" {
  service            = "cloudscheduler.googleapis.com"
  project            = var.workflow_deployment_project
  disable_on_destroy = false
}

resource "google_cloud_scheduler_job" "long_running_jobs_workflow_invoker" {

  depends_on = [google_project_service.cloud_scheduler]

  name        = "long-running-jobs-workflow-invoker"
  description = "Cloud Scheduler Invoker for the Long Running Jobs Workflow"
  schedule    = var.long_running_job_polling_period
  project     = var.workflow_deployment_project
  region      = var.workflow_deployment_region

  paused = false

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${google_workflows_workflow.long_running_jobs.project}/locations/${google_workflows_workflow.long_running_jobs.region}/workflows/${google_workflows_workflow.long_running_jobs.name}/executions"
    body = base64encode(jsonencode({
      argument = jsonencode({
        targets : var.monitored_projects_and_regions,
        config = {
          "masterQueryProject" : var.master_query_project == "" ? null : var.master_query_project,
          "masterMetricProject" : var.master_metrics_project == "" ? null : var.master_metrics_project,
          "jobDurationAlertThreshold" : tostring(var.job_duration_alert_threshold_minutes)
        }
      })
      "callLogLevel" : "CALL_LOG_LEVEL_UNSPECIFIED"
    }))

    oauth_token {
      service_account_email = google_service_account.long_running_jobs_workflow_invoker.email
    }
  }





}
