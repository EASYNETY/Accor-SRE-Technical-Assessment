{{- define "redemption.name" -}}
redemption-api
{{- end -}}

{{- define "redemption.fullname" -}}
{{ include "redemption.name" . }}
{{- end -}}

{{- define "redemption.labels" -}}
app: {{ include "redemption.name" . }}
environment: {{ .Values.environment | default "prod" }}
{{- end -}}

{{- define "redemption.serviceAccountName" -}}
redemption-api-sa
{{- end -}}
