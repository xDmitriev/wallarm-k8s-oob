{{/*
Expand the name of the chart.
*/}}
{{- define "processing.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "processing.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "processing.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{ template "processing.fullname" . }}
{{- else -}}
{{- .Values.serviceAccount.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "processing.labels" -}}
helm.sh/chart: {{ .Chart.Name | quote }}
{{ include "processing.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- if .Values.extraLabels }}
{{ toYaml .Values.extraLabels }}
{{- end }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "processing.selectorLabels" -}}
app.kubernetes.io/name: {{ include "processing.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Annotations
*/}}
{{- define "processing.annotations" -}}
{{- if .Values.extraAnnotations -}}
{{- toYaml .Values.extraAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Docker image name
*/}}
{{- define "processing.image" -}}
{{- if .registry -}}
{{- printf "%s/%s:%s" .registry .name .tag -}}
{{- else -}}
{{- printf "%s:%s" .name .tag -}}
{{- end -}}
{{- end -}}

{{/*
Env set: Paperless
*/}}
{{- define "processing.envs.paperless" -}}
# PAPERLESS_SECRET_KEY
- name: PAPERLESS_TASK_WORKERS
  value: {{ .Values.config.processing.workers | quote }}
{{- with .Values.config.processing.url }}
- name: PAPERLESS_URL
  value: {{ . | quote }}
{{- end }}
- name: PAPERLESS_SECRET_KEY
  value: {{ .Values.config.processing.secret | quote }}
- name: PAPERLESS_TIME_ZONE
  value: {{ .Values.config.processing.tz | quote }}
- name: PAPERLESS_OCR_LANGUAGE
  value: "eng"
{{- with .Values.config.processing.auto_login_username }}
- name: PAPERLESS_AUTO_LOGIN_USERNAME
  value: {{ . | quote }}
{{- end }}
{{- if .Values.config.gotenberg_tika.enabled }}
- name: PAPERLESS_TIKA_ENABLED
  value: "1"
- name: PAPERLESS_TIKA_GOTENBERG_ENDPOINT
  value: http://{{ template "processing.fullname" . }}-gotenberg:3000
- name: PAPERLESS_TIKA_ENDPOINT
  value: http://{{ template "processing.fullname" . }}-tika:9998
{{- end }}

{{- if .Values.config.auth.external_sso_mode }}
- name: PAPERLESS_ENABLE_HTTP_REMOTE_USER
  value: "yes"
- name: PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME
  value: {{ .Values.config.auth.external_sso_header_name | quote }}
{{- end }}
{{- end -}}

{{/*
Env set: PostgreSQL
*/}}
{{- define "processing.envs.postgres" -}}
- name: PAPERLESS_DBUSER
  value: {{ .Values.config.postgres.user | quote }}
- name: PAPERLESS_DBPASS
  value: {{ .Values.config.postgres.password | quote }}
- name: PAPERLESS_DBHOST
  value: {{ .Values.config.postgres.host | quote }}
- name: PAPERLESS_DBNAME
  value: {{ .Values.config.postgres.dbname | quote }}
- name: PAPERLESS_DBPORT
  value: {{ .Values.config.postgres.port | quote }}
{{- end -}}

{{/*
Env set: Redis
*/}}
{{- define "processing.envs.redis" -}}
- name: PAPERLESS_REDIS
{{- if .Values.config.redis.password }}
  value: {{ printf "redis://:%s@%s:%d/%d" .Values.config.redis.password .Values.config.redis.host (.Values.config.redis.port | int) (.Values.config.redis.db | int) | quote }}
{{- else }}
  value: {{ printf "redis://%s:%d/%d" .Values.config.redis.host (.Values.config.redis.port | int) (.Values.config.redis.db | int) | quote }}
{{- end }}
{{- end -}}
