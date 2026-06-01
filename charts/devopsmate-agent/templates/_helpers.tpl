{{/* Common name helpers */}}
{{- define "devopsmate-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "devopsmate-agent.fullname" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "devopsmate-agent.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride -}}
{{- end -}}

{{- define "devopsmate-agent.labels" -}}
app.kubernetes.io/name: {{ include "devopsmate-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "devopsmate-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "devopsmate-agent.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "devopsmate-agent.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}

{{/* API-key Secret name/key (created here, or pre-existing) */}}
{{- define "devopsmate-agent.apiKeySecretName" -}}
{{- if .Values.apiKey.existingSecret -}}
{{- .Values.apiKey.existingSecret -}}
{{- else -}}
{{- printf "%s-token" (include "devopsmate-agent.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "devopsmate-agent.apiKeySecretKey" -}}
{{- if .Values.apiKey.existingSecret -}}
{{- .Values.apiKey.existingSecretKey -}}
{{- else -}}
api-key
{{- end -}}
{{- end -}}

{{/*
Footprint profile map. Returns a dict for the selected profile.
Lightweight = fewer scrapers + capped runtime; intervals stay short (real-time).
*/}}
{{- define "devopsmate-agent.profile" -}}
{{- $p := .Values.profile | default "standard" -}}
{{- $map := dict
  "minimal"  (dict "interval" "15s" "memLimitMib" 96  "spikeMib" 32  "gomemlimit" "100MiB" "gomaxprocs" "1" "cpuReq" "50m"  "memReq" "64Mi"  "cpuLim" "300m" "memLim" "128Mi" "extraScrapers" (list))
  "standard" (dict "interval" "10s" "memLimitMib" 200 "spikeMib" 64  "gomemlimit" "220MiB" "gomaxprocs" "2" "cpuReq" "100m" "memReq" "128Mi" "cpuLim" "500m" "memLim" "256Mi" "extraScrapers" (list "paging"))
  "full"     (dict "interval" "5s"  "memLimitMib" 400 "spikeMib" 128 "gomemlimit" "460MiB" "gomaxprocs" "2" "cpuReq" "200m" "memReq" "256Mi" "cpuLim" "1"    "memLim" "512Mi" "extraScrapers" (list "paging" "processes"))
-}}
{{- get $map $p | default (get $map "standard") | toJson -}}
{{- end -}}

{{/* Common env block (token from Secret, identity + runtime bounds) for collector pods */}}
{{- define "devopsmate-agent.commonEnv" -}}
{{- $prof := include "devopsmate-agent.profile" . | fromJson -}}
- name: DEVOPSMATE_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "devopsmate-agent.apiKeySecretName" . }}
      key: {{ include "devopsmate-agent.apiKeySecretKey" . }}
- name: DEVOPSMATE_TENANT_ID
  value: {{ .Values.global.tenantId | quote }}
- name: OTEL_ENVIRONMENT
  value: {{ .Values.global.env | quote }}
- name: DEVOPSMATE_GATEWAY_ENDPOINT
  value: {{ .Values.gateway.endpoint | quote }}
- name: DEVOPSMATE_OTLP_INSECURE
  value: {{ .Values.gateway.tls.insecure | quote }}
- name: DEVOPSMATE_TLS_SKIP_VERIFY
  value: {{ .Values.gateway.tls.insecureSkipVerify | quote }}
- name: K8S_NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
- name: GOMEMLIMIT
  value: {{ $prof.gomemlimit | quote }}
- name: GOMAXPROCS
  value: {{ $prof.gomaxprocs | quote }}
{{- end -}}
