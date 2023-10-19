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


resource "google_project_service" "long_running_jobs_monitoring_api" {

  # If we do not have a master_metrics_project set, then the metrics will be shipped to each project we are configured to
  # monitor. So we need to enable the monitoring API in every project.
  # If we have a master_metrics_project set, then metrics will only go to this project so we just enable the monitoring API
  # there
  count = var.master_metrics_project == "" ? length(keys(var.monitored_projects_and_regions)) : 1

  project            = var.master_metrics_project == "" ? keys(var.monitored_projects_and_regions)[count.index] : var.master_metrics_project
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false

}


resource "google_monitoring_metric_descriptor" "bigquery_long_running_jobs" {

  depends_on = [google_project_service.long_running_jobs_monitoring_api]

  # If we do not have a master_metrics_project set, then the metrics will be shipped to each project we are configured to
  # monitor. So we need to create a metrics descriptor in every project.
  # If we have a master_metrics_project set, then metrics will only go to this project so we just create the metrics
  # descriptor there
  count = var.master_metrics_project == "" ? length(keys(var.monitored_projects_and_regions)) : 1

  description  = "BigQuery Long Running Jobs"
  display_name = "Long running job count"
  type         = "custom.googleapis.com/bigquery/long_running_jobs"
  metric_kind  = "GAUGE"
  value_type   = "INT64"
  project      = var.master_metrics_project == "" ? keys(var.monitored_projects_and_regions)[count.index] : var.master_metrics_project

  labels {
    key         = "region"
    value_type  = "STRING"
    description = "The region of the job"
  }

  labels {
    key         = "project"
    value_type  = "STRING"
    description = "The project ID of the job"
  }

}

resource "google_project_iam_member" "long_running_jobs_metrics_writer" {

  # If we do not have a master_metrics_project set, then the metrics will be shipped to each project we are configured to
  # monitor. So we need permission to write metrics in every projects.
  # If we have a master_metrics_project set, then metrics will only go to this project so we just add the IAM role there
  count = var.master_metrics_project == "" ? length(keys(var.monitored_projects_and_regions)) : 1

  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.long_running_jobs.email}"
  project = var.master_metrics_project == "" ? keys(var.monitored_projects_and_regions)[count.index] : var.master_metrics_project

}
