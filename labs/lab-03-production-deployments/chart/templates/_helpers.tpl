{{/*
Expand the chart name.
*/}}
{{- define "lab03.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the workload name. This chart defaults to the original lab name: web-app.
*/}}
{{- define "lab03.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label value.
*/}}
{{- define "lab03.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for objects managed by Helm.
*/}}
{{- define "lab03.labels" -}}
helm.sh/chart: {{ include "lab03.chart" . }}
{{ include "lab03.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels. The simple app label is preserved for the original lab selectors.
*/}}
{{- define "lab03.selectorLabels" -}}
app: {{ include "lab03.fullname" . }}
app.kubernetes.io/name: {{ include "lab03.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
