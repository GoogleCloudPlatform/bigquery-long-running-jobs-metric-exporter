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

module "long-running-jobs" {

  source = "./terraform-module-long-running-jobs"

  # These variables determine where the Workflow itself is deployed.
  # A Service Account is also created in this project which is used
  # for making the BigQuery Queries to determine long running jobs,
  # and also to write metrics and logs from the Workflow run
  workflow_deployment_project = "bigquery-job-alerting"
  workflow_deployment_region  = "europe-west2"

  # map(list(string)) of projects and regions to monitor for long running jobs
  # This variable defines the projects to be monitored, and which regions within
  # that project to monitor
  monitored_projects_and_regions = {
    "bigquery-job-alerting" = ["US", "EU", "europe-west2"],
  }

  # The duration queries should be running for before the alert is triggered
  job_duration_alert_threshold_minutes = 20

  # By default, queries for long running jobs are performed in the project that is being
  # queried. For example if two projects "project-a" and "project-b" are being monitored,
  # the query for "project-a" is run in "project-a", and the query for "project-b" is run
  # in "project-b".
  #
  # In some scenarios - it may be desirable to run all of the queries from a single project.
  # In order to do this, set the master_query_project below to a valid project ID
  master_query_project = ""

  # By default, metrics for long running jobs are stored in the project that is being
  # queried. For example if two projects "project-a" and "project-b" are being monitored,
  # the long running jobs metric for "project-a" is stored in "project-a", and the long
  # running jobs metric for "project-b" is stored in "project-b".
  #
  # In some scenarios - it may be desirable to aggregate all metrics in a single project
  # In order to do this, set the master_metrics_project below to a valid project ID
  master_metrics_project = ""

  # How often should a query be made for Long Running Jobs? This should be in Crontab format and
  # defaults to every 5 minutes
  long_running_job_polling_period = "*/5 * * * *"

}
