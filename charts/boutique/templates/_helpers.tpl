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
app.kubernetes.io/name: {{ include "boutique.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app: {{ .name }}
{{- end }}

{{- define "boutique.image" -}}
{{- printf "%s/%s:%s" .root.Values.image.registry .name .root.Values.image.tag }}
{{- end }}

{{/*
Deployment + ClusterIP Service for a values-driven microservice.
Usage: {{ include "boutique.microservice" (dict "root" . "name" "adservice") }}
*/}}
{{- define "boutique.microservice" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $svc := index $root.Values.services $name -}}
{{- if not $svc }}
{{- fail (printf "values.yaml is missing services.%s" $name) }}
{{- end }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $name }}
  labels:
    app: {{ $name }}
    {{- include "boutique.labels" $root | nindent 4 }}
spec:
  replicas: {{ $svc.replicas }}
  selector:
    matchLabels:
      app: {{ $name }}
  template:
    metadata:
      labels:
        app: {{ $name }}
        {{- include "boutique.selectorLabels" (dict "root" $root "name" $name) | nindent 8 }}
    spec:
      terminationGracePeriodSeconds: 5
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsNonRoot: true
        runAsUser: 1000
      containers:
        - name: server
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            privileged: false
            readOnlyRootFilesystem: true
          image: {{ include "boutique.image" (dict "root" $root "name" $name) | quote }}
          imagePullPolicy: {{ $root.Values.image.pullPolicy }}
          ports:
            - containerPort: {{ $svc.containerPort }}
          env:
            {{- if eq $name "checkoutservice" }}
            {{- range $k, $v := $root.Values.checkoutEnv }}
            - name: {{ $k }}
              value: {{ $v | quote }}
            {{- end }}
            {{- else if $svc.env }}
            {{- range $k, $v := $svc.env }}
            - name: {{ $k }}
              value: {{ $v | quote }}
            {{- end }}
            {{- end }}
          readinessProbe:
            initialDelaySeconds: 10
            tcpSocket:
              port: {{ $svc.containerPort }}
          livenessProbe:
            periodSeconds: 10
            tcpSocket:
              port: {{ $svc.containerPort }}
          resources:
            {{- toYaml $root.Values.defaults.resources | nindent 12 }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $name }}
  labels:
    app: {{ $name }}
    {{- include "boutique.labels" $root | nindent 4 }}
spec:
  type: {{ $svc.type | default "ClusterIP" }}
  selector:
    app: {{ $name }}
  ports:
    - name: grpc
      port: {{ $svc.servicePort }}
      targetPort: {{ $svc.containerPort }}
{{- end }}
