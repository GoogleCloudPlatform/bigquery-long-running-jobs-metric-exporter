# bigquery-long-running-jobs-metric-exporter

This repository contains a [Google Cloud Workflow](https://cloud.google.com/workflows?hl=en) that exports a count of long running BigQuery queries into Google [Cloud Monitoring](https://cloud.google.com/monitoring?hl=en) as a [user-defined metric](https://cloud.google.com/monitoring/custom-metrics).

The monitored projects, and BigQuery regions are configurable, alongside the query duration that constitutes "long running". Once deployed, this Workflow exports a custom GAUGE metric `custom.googleapis.com/bigquery/long_running_jobs` labelled with the project ID and BigQuery region with the count of long running queries.

You are then able to use the standard Google Cloud Monitoring tool set such as alerting, and dashboarding to monitor these queries.

## How it works

The Workflow is invoked by Cloud Scheduler, with a payload containing the configuration. An example payload is as follows:

```
{
  "config": {
    "masterMetricProject": null,
    "masterQueryProject": null,
    "queryDurationAlertThreshold": "30"
  },
  "targets": {
    "bigquery-project-1": [
      "US",
      "EU",
      "europe-west2"
    ],
    "bigquery-project-2": [
      "europe-west2"
    ]
  }
}
```

The Workflow iterates through all of the keys (Project ID's) in `.targets` - for each target (project ID) it then iterates through each of the array items (BigQuery regions).

For each provided project and region, the Workflow runs a BigQuery query to report on outstanding jobs that are still running:

```
SELECT job_id FROM `<PROJECT_ID>`.`region-<REGION_ID>`.INFORMATION_SCHEMA.JOBS_BY_PROJECT WHERE state!=\"DONE\" AND creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL <CONFIGURED_INTERVAL> MINUTE)
```

The number of rows returned by this query is then written as a metric into Google Cloud Monitoring (`custom.googleapis.com/bigquery/long_running_jobs`) labelled with the project id and the region.

## Where are queries performed, and where are metrics stored?

By default, the Workflow runs the outstanding jobs query in the project that is being queried for running jobs.

```
"targets": {
    "bigquery-project-1": [
      "US",
      "EU",
      "europe-west2"
    ],
    "bigquery-project-2": [
      "europe-west2"
    ]
}
```

For example, with the above configuration the query for outstanding jobs in `bigquery-project-1` will be ran in `bigquery-project-1`, and the query for outstanding jobs in `bigquery-project-2` will be ran in `bigquery-project-2`.

In some scenarios, it may be desired to execute the queries all from a single project. This can be easily configured by configuring the `master_query_project` variable in module definition shown in the [Deployment](#deployment) section. When this variable is set, all queries will be executed from the project defined in `master_query_project`.

The same is true for metrics, by default, metrics are written to their respective projects.

In some scenarios, it may be desired to write metrics from multiple monitored projects to a single metrics project. This can be easily configured by configuring the `master_metrics_project` variable in module definition shown in the [Deployment](#deployment) section. When this variable is set, all metrics will be stored in the project defined in `master_metrics_project`.

## Permissions

All queries, and metric writes are performed by a Service Account specifically created for the Cloud Workflow (`long-running-jobs-workflow@<projectID.iam.gserviceaccount.com`). Consequently, this Service Account needs some basic permissions:

1. `roles/bigquery.resourceViewer` - Required in every project being monitored for long running jobs. This provides access to the `INFORMATION_SCHEMA` tables
2. `roles/bigquery.jobUser` - Required in every project being monitored, unless `master_query_project` is set (in which case it is only required there). This allows the Workflow to run queries.
3. `roles/monitoring.metricWriter` - Required in every project being monitored, unless `master_metrics_project` is set (in which case it is only required there). This allows the Workflow to write the outstanding jobs count to Google Cloud Monitoring.

**Terraform handles all of these permissions automatically, including dynamically creating the required permissions depending on whether `master_query_project`/`master_metrics_project` is set.**


## Deployment

This repository contains a Terraform Module that automatically deploys all of the required Google Cloud components to setup this metric. The module:

You can import the module to an existing Terraform configuration, or define it in a standalone configuration.

The configuration variables are documented inline below:

```
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
  query_duration_alert_threshold_minutes = 30

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
  query_schedule = "*/5 * * * *"



}
```