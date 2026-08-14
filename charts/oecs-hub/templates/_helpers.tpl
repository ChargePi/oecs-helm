{{/*
Expand the name of the chart.
*/}}
{{- define "oecs-hub.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "oecs-hub.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "oecs-hub.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "oecs-hub.labels" -}}
helm.sh/chart: {{ include "oecs-hub.chart" . }}
{{ include "oecs-hub.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "oecs-hub.selectorLabels" -}}
app.kubernetes.io/name: {{ include "oecs-hub.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "oecs-hub.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{ default (include "oecs-hub.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "oecs-hub.image" -}}
{{- $img := .Values.image -}}
{{- printf "%s/%s:%s" $img.registry $img.repository (default .Chart.AppVersion $img.tag) -}}
{{- end -}}

{{/*
Image used by the migration Job: .Values.migration.image, filling in any unset fields
(registry/repository/tag) from the top-level .Values.image.
*/}}
{{- define "oecs-hub.migrationImage" -}}
{{- $img := .Values.image -}}
{{- if .Values.migration.image -}}
{{- $img = merge .Values.migration.image .Values.image -}}
{{- end -}}
{{- printf "%s/%s:%s" $img.registry $img.repository (default .Chart.AppVersion $img.tag) -}}
{{- end -}}

{{/*
Renders a single secretKeyRef env var entry, or nothing if neither `value` nor
`existingSecret` is set on the field spec.
Call with a dict: (dict "envName" "FOO" "spec" .Values.secrets.x.y "defaultSecretName" "my-secret")
*/}}
{{- define "oecs-hub.secretEnv" -}}
{{- $spec := .spec -}}
{{- if or $spec.value $spec.existingSecret -}}
- name: {{ .envName }}
  valueFrom:
    secretKeyRef:
      name: {{ $spec.existingSecret | default .defaultSecretName }}
      key: {{ $spec.existingSecretKey }}
{{ end -}}
{{- end -}}

{{/*
Name of the chart-managed Secret holding inline `value`s from .Values.secrets.*
*/}}
{{- define "oecs-hub.secretName" -}}
{{ include "oecs-hub.fullname" . }}-secrets
{{- end -}}

{{/*
Database DSN env entry. When postgresql.internal.enabled, points at the CloudNativePG-
generated app secret instead of .Values.secrets.database.dsn.
*/}}
{{- define "oecs-hub.databaseEnv" -}}
{{- if .Values.postgresql.internal.enabled -}}
- name: OECS_HUB_DATABASE_DSN
  valueFrom:
    secretKeyRef:
      name: {{ include "oecs-hub.fullname" . }}-postgresql-app
      key: uri
{{- else -}}
{{ include "oecs-hub.secretEnv" (dict "envName" "OECS_HUB_DATABASE_DSN" "spec" .Values.secrets.database.dsn "defaultSecretName" (include "oecs-hub.secretName" .)) }}
{{- end -}}
{{- end -}}

{{/*
Remaining sensitive env vars (redis/memgraph/profiling), always sourced per the generic pattern.
*/}}
{{- define "oecs-hub.sensitiveEnv" -}}
{{ include "oecs-hub.secretEnv" (dict "envName" "OECS_HUB_REDIS_PASSWORD" "spec" .Values.secrets.redis.password "defaultSecretName" (include "oecs-hub.secretName" .)) }}
{{ include "oecs-hub.secretEnv" (dict "envName" "OECS_HUB_MEMGRAPH_USERNAME" "spec" .Values.secrets.memgraph.username "defaultSecretName" (include "oecs-hub.secretName" .)) }}
{{ include "oecs-hub.secretEnv" (dict "envName" "OECS_HUB_MEMGRAPH_PASSWORD" "spec" .Values.secrets.memgraph.password "defaultSecretName" (include "oecs-hub.secretName" .)) }}
{{ include "oecs-hub.secretEnv" (dict "envName" "OECS_HUB_OBSERVABILITY_PROFILING_USERNAME" "spec" .Values.secrets.profiling.username "defaultSecretName" (include "oecs-hub.secretName" .)) }}
{{ include "oecs-hub.secretEnv" (dict "envName" "OECS_HUB_OBSERVABILITY_PROFILING_PASSWORD" "spec" .Values.secrets.profiling.password "defaultSecretName" (include "oecs-hub.secretName" .)) }}
{{ include "oecs-hub.secretEnv" (dict "envName" "OECS_HUB_OBSERVABILITY_PROFILING_AUTHTOKEN" "spec" .Values.secrets.profiling.authToken "defaultSecretName" (include "oecs-hub.secretName" .)) }}
{{- end -}}

{{/*
Memgraph bolt address: auto-derived from the bundled subchart's default service name when
memgraph.enabled, otherwise the user-supplied external address.
*/}}
{{- define "oecs-hub.memgraphAddress" -}}
{{- if .Values.memgraph.enabled -}}
{{- $name := .Values.memgraph.fullnameOverride | default (printf "%s-memgraph" .Release.Name) -}}
bolt://{{ $name }}:{{ ((.Values.memgraph).service).boltPort | default 7687 }}
{{- else -}}
{{ .Values.memgraph.address }}
{{- end -}}
{{- end -}}

{{/*
Redis/Valkey address: auto-derived from the bundled subchart's default service name when
valkey.enabled, otherwise the user-supplied external address.
*/}}
{{- define "oecs-hub.redisAddress" -}}
{{- if .Values.valkey.enabled -}}
{{- $name := .Values.valkey.fullnameOverride | default (printf "%s-valkey" .Release.Name) -}}
{{ $name }}:{{ ((.Values.valkey).service).port | default 6379 }}
{{- else -}}
{{ .Values.valkey.address }}
{{- end -}}
{{- end -}}
