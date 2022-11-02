{{/*
Expand the name of the chart.
*/}}
{{- define "wallarm-oob.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "wallarm-oob.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "wallarm-oob.labels" -}}
helm.sh/chart: {{ .Chart.Name | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- if .Values.extraLabels }}
{{ toYaml .Values.extraLabels }}
{{- end }}
{{- end -}}


{{- define "processing.fullname" }}
{{- printf "%s-%s" (include "wallarm-oob.fullname") "processing" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "aggregation.fullname" }}
{{- printf "%s-%s" (include "wallarm-oob.fullname") "aggregation" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{ template "wallarm-oob.fullname" . }}
{{- else -}}
{{- .Values.serviceAccount.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Labels for Processing Unit
*/}}
{{- define "processing.labels" -}}
{{ include "wallarm-oob.labels" }}
{{ include "processing.selectorLabels"}}
{{- end -}}

{{/*
Labels for Aggregation Unit
*/}}
{{- define "aggregation.labels" -}}
{{ include "wallarm-oob.labels" }}
{{ include "aggregation.selectorLabels"}}
{{- end -}}


{{/*
Selector labels for Processing Unit
*/}}
{{- define "processing.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wallarm-oob.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "processing"
{{- end -}}

{{/*
Selector labels for Aggregation Unit
*/}}
{{- define "aggregation.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wallarm-oob.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "aggregation"
{{- end -}}


{{/*
Common annotations
*/}}
{{- define "wallarm-oob.annotations" -}}
{{- if .Values.extraAnnotations -}}
{{- toYaml .Values.extraAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Docker image name
*/}}
{{- define "image" -}}
{{- if .registry -}}
{{- printf "%s/%s:%s" .registry .name .tag -}}
{{- else -}}
{{- printf "%s:%s" .name .tag -}}
{{- end -}}
{{- end -}}


{{- define "wallarm-oob.credentials" -}}
- name: WALLARM_API_HOST
  valueFrom:
    secretKeyRef:
      key: WALLARM_API_HOST
      name: {{ template "wallarm-oob.fullname" . }}-credentials
- name: WALLARM_API_PORT
  valueFrom:
    secretKeyRef:
      key: WALLARM_API_PORT
      name: {{ template "wallarm-oob.fullname" . }}-credentials
- name: WALLARM_API_USE_SSL
  valueFrom:
    secretKeyRef:
      key: WALLARM_API_USE_SSL
      name: {{ template "wallarm-oob.fullname" . }}-credentials
- name: WALLARM_API_CA_VERIFY
  valueFrom:
    secretKeyRef:
      key: WALLARM_API_CA_VERIFY
      name: {{ template "wallarm-oob.fullname" . }}-credentials
- name: WALLARM_API_TOKEN
  valueFrom:
    secretKeyRef:
      key: WALLARM_API_TOKEN
      name: {{ template "wallarm-oob.fullname" . }}-credentials
{{- end -}}
