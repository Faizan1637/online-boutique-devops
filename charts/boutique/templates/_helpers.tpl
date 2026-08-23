{{- define "boutique.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "boutique.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "boutique.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "boutique.selectorLabels" -}}
app.kubernetes.io/name: {{ include "boutique.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ .name }}
{{- end }}