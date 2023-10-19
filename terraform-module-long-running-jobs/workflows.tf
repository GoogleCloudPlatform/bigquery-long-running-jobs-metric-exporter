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

resource "google_project_service" "workflows_api" {
  project            = var.workflow_deployment_project
  service            = "workflows.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "long_running_jobs" {
  account_id   = "long-running-jobs-workflow"
  display_name = "Service Account for the long-running-jobs workfow"
  project      = var.workflow_deployment_project
}

resource "google_project_iam_member" "long_running_jobs_logging" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.long_running_jobs.email}"
  project = var.workflow_deployment_project
}

resource "google_workflows_workflow" "long_running_jobs" {

  depends_on = [google_project_service.workflows_api]

  name            = "long-running-jobs"
  region          = var.workflow_deployment_region
  description     = "Workflow that monitors for long running BigQuery Jobs"
  service_account = google_service_account.long_running_jobs.id
  project         = var.workflow_deployment_project

  source_contents = file("${path.root}/workflow/long-running-jobs.yaml")

}
