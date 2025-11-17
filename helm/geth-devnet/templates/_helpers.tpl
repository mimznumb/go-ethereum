{{/*
Return the name of the chart
*/}}
{{- define "geth-devnet.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Return a fully qualified app name
*/}}
{{- define "geth-devnet.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else }}
{{- $name := include "geth-devnet.name" . -}}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "geth-devnet.labels" -}}
app.kubernetes.io/name: {{ include "geth-devnet.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "geth-devnet.selectorLabels" -}}
app.kubernetes.io/name: {{ include "geth-devnet.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
