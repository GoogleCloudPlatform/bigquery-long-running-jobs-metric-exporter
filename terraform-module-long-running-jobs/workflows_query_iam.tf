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


resource "google_project_iam_member" "long_running_jobs_bigquery_jobuser" {

  # If we do not have a master_query_project set, then the query will be performed for the project we are monitoring
  # so we need the bigquery.jobUser on every project
  # If we have a master_query_project set, then the query will only be performed from that project so we will only
  # grant the role there
  count = var.master_query_project == "" ? length(keys(var.monitored_projects_and_regions)) : 1

  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.long_running_jobs.email}"
  project = var.master_query_project == "" ? keys(var.monitored_projects_and_regions)[count.index] : var.master_metrics_project

}

resource "google_project_iam_member" "long_running_jobs_bigquery_resourceviewer" {

  # We need the bigquery.resourceViewer role on every project we are monitoring so we can access the schema tables
  count = length(keys(var.monitored_projects_and_regions))

  role    = "roles/bigquery.resourceViewer"
  member  = "serviceAccount:${google_service_account.long_running_jobs.email}"
  project = keys(var.monitored_projects_and_regions)[count.index]

}

