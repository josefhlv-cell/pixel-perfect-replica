export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      agent_versions: {
        Row: {
          agent_id: string
          created_at: string
          created_by: string | null
          id: string
          organization_id: string
          snapshot: Json
          updated_at: string
          version: number
        }
        Insert: {
          agent_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          organization_id: string
          snapshot: Json
          updated_at?: string
          version: number
        }
        Update: {
          agent_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          organization_id?: string
          snapshot?: Json
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "agent_versions_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "agent_versions_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      agents: {
        Row: {
          business_info: Json
          call_behavior: Json
          created_at: string
          created_by: string | null
          current_version: number
          description: string | null
          greeting_message: string
          id: string
          llm_model: string | null
          llm_provider: string
          name: string
          operating_hours: Json
          organization_id: string
          primary_language: string
          status: Database["public"]["Enums"]["agent_status"]
          supported_languages: string[]
          system_instructions: string
          timezone: string
          transfer_rules: Json
          updated_at: string
          voice_id: string | null
          voice_provider: string
        }
        Insert: {
          business_info?: Json
          call_behavior?: Json
          created_at?: string
          created_by?: string | null
          current_version?: number
          description?: string | null
          greeting_message?: string
          id?: string
          llm_model?: string | null
          llm_provider?: string
          name: string
          operating_hours?: Json
          organization_id: string
          primary_language?: string
          status?: Database["public"]["Enums"]["agent_status"]
          supported_languages?: string[]
          system_instructions?: string
          timezone?: string
          transfer_rules?: Json
          updated_at?: string
          voice_id?: string | null
          voice_provider?: string
        }
        Update: {
          business_info?: Json
          call_behavior?: Json
          created_at?: string
          created_by?: string | null
          current_version?: number
          description?: string | null
          greeting_message?: string
          id?: string
          llm_model?: string | null
          llm_provider?: string
          name?: string
          operating_hours?: Json
          organization_id?: string
          primary_language?: string
          status?: Database["public"]["Enums"]["agent_status"]
          supported_languages?: string[]
          system_instructions?: string
          timezone?: string
          transfer_rules?: Json
          updated_at?: string
          voice_id?: string | null
          voice_provider?: string
        }
        Relationships: [
          {
            foreignKeyName: "agents_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "agents_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      api_keys: {
        Row: {
          created_at: string
          created_by: string
          expires_at: string | null
          id: string
          key_hash: string
          key_prefix: string
          last_used_at: string | null
          name: string
          organization_id: string
          rate_limit_per_minute: number
          revoked_at: string | null
          scopes: string[]
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by: string
          expires_at?: string | null
          id?: string
          key_hash: string
          key_prefix: string
          last_used_at?: string | null
          name: string
          organization_id: string
          rate_limit_per_minute?: number
          revoked_at?: string | null
          scopes?: string[]
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string
          expires_at?: string | null
          id?: string
          key_hash?: string
          key_prefix?: string
          last_used_at?: string | null
          name?: string
          organization_id?: string
          rate_limit_per_minute?: number
          revoked_at?: string | null
          scopes?: string[]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "api_keys_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "api_keys_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_logs: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          entity_id: string | null
          entity_type: string
          id: string
          metadata: Json
          organization_id: string | null
          updated_at: string
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type: string
          id?: string
          metadata?: Json
          organization_id?: string | null
          updated_at?: string
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type?: string
          id?: string
          metadata?: Json
          organization_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      call_events: {
        Row: {
          call_session_id: string
          created_at: string
          event_type: string
          id: string
          occurred_at: string
          organization_id: string
          payload: Json
          updated_at: string
        }
        Insert: {
          call_session_id: string
          created_at?: string
          event_type: string
          id?: string
          occurred_at?: string
          organization_id: string
          payload?: Json
          updated_at?: string
        }
        Update: {
          call_session_id?: string
          created_at?: string
          event_type?: string
          id?: string
          occurred_at?: string
          organization_id?: string
          payload?: Json
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "call_events_call_session_id_fkey"
            columns: ["call_session_id"]
            isOneToOne: false
            referencedRelation: "call_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "call_events_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      call_sessions: {
        Row: {
          agent_id: string | null
          agent_version: number | null
          answered_at: string | null
          created_at: string
          direction: Database["public"]["Enums"]["call_direction"]
          duration_seconds: number | null
          end_reason: string | null
          ended_at: string | null
          from_number: string | null
          id: string
          language: string | null
          metadata: Json
          organization_id: string
          phone_number_id: string | null
          provider: string | null
          provider_call_id: string | null
          started_at: string | null
          status: Database["public"]["Enums"]["call_status"]
          to_number: string | null
          updated_at: string
        }
        Insert: {
          agent_id?: string | null
          agent_version?: number | null
          answered_at?: string | null
          created_at?: string
          direction: Database["public"]["Enums"]["call_direction"]
          duration_seconds?: number | null
          end_reason?: string | null
          ended_at?: string | null
          from_number?: string | null
          id?: string
          language?: string | null
          metadata?: Json
          organization_id: string
          phone_number_id?: string | null
          provider?: string | null
          provider_call_id?: string | null
          started_at?: string | null
          status?: Database["public"]["Enums"]["call_status"]
          to_number?: string | null
          updated_at?: string
        }
        Update: {
          agent_id?: string | null
          agent_version?: number | null
          answered_at?: string | null
          created_at?: string
          direction?: Database["public"]["Enums"]["call_direction"]
          duration_seconds?: number | null
          end_reason?: string | null
          ended_at?: string | null
          from_number?: string | null
          id?: string
          language?: string | null
          metadata?: Json
          organization_id?: string
          phone_number_id?: string | null
          provider?: string | null
          provider_call_id?: string | null
          started_at?: string | null
          status?: Database["public"]["Enums"]["call_status"]
          to_number?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "call_sessions_agent_id_fkey"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "call_sessions_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "call_sessions_phone_number_id_fkey"
            columns: ["phone_number_id"]
            isOneToOne: false
            referencedRelation: "phone_numbers"
            referencedColumns: ["id"]
          },
        ]
      }
      call_transcripts: {
        Row: {
          call_session_id: string
          confidence: number | null
          content: string
          created_at: string
          end_ms: number | null
          id: string
          language: string | null
          organization_id: string
          sequence: number
          speaker: string
          start_ms: number | null
          updated_at: string
        }
        Insert: {
          call_session_id: string
          confidence?: number | null
          content: string
          created_at?: string
          end_ms?: number | null
          id?: string
          language?: string | null
          organization_id: string
          sequence: number
          speaker: string
          start_ms?: number | null
          updated_at?: string
        }
        Update: {
          call_session_id?: string
          confidence?: number | null
          content?: string
          created_at?: string
          end_ms?: number | null
          id?: string
          language?: string | null
          organization_id?: string
          sequence?: number
          speaker?: string
          start_ms?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "call_transcripts_call_session_id_fkey"
            columns: ["call_session_id"]
            isOneToOne: false
            referencedRelation: "call_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "call_transcripts_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      integrations: {
        Row: {
          category: string
          config: Json
          connected_at: string | null
          created_at: string
          display_name: string
          id: string
          organization_id: string
          provider: string
          secret_ref: string | null
          status: Database["public"]["Enums"]["integration_status"]
          updated_at: string
        }
        Insert: {
          category: string
          config?: Json
          connected_at?: string | null
          created_at?: string
          display_name: string
          id?: string
          organization_id: string
          provider: string
          secret_ref?: string | null
          status?: Database["public"]["Enums"]["integration_status"]
          updated_at?: string
        }
        Update: {
          category?: string
          config?: Json
          connected_at?: string | null
          created_at?: string
          display_name?: string
          id?: string
          organization_id?: string
          provider?: string
          secret_ref?: string | null
          status?: Database["public"]["Enums"]["integration_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "integrations_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      organization_invitations: {
        Row: {
          accepted_at: string | null
          created_at: string
          email: string
          expires_at: string
          id: string
          invited_by: string
          organization_id: string
          role: Database["public"]["Enums"]["org_role"]
          status: Database["public"]["Enums"]["invitation_status"]
          token_hash: string
          updated_at: string
        }
        Insert: {
          accepted_at?: string | null
          created_at?: string
          email: string
          expires_at?: string
          id?: string
          invited_by: string
          organization_id: string
          role?: Database["public"]["Enums"]["org_role"]
          status?: Database["public"]["Enums"]["invitation_status"]
          token_hash: string
          updated_at?: string
        }
        Update: {
          accepted_at?: string | null
          created_at?: string
          email?: string
          expires_at?: string
          id?: string
          invited_by?: string
          organization_id?: string
          role?: Database["public"]["Enums"]["org_role"]
          status?: Database["public"]["Enums"]["invitation_status"]
          token_hash?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "organization_invitations_invited_by_fkey"
            columns: ["invited_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "organization_invitations_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      organization_members: {
        Row: {
          created_at: string
          id: string
          organization_id: string
          role: Database["public"]["Enums"]["org_role"]
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          organization_id: string
          role?: Database["public"]["Enums"]["org_role"]
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          organization_id?: string
          role?: Database["public"]["Enums"]["org_role"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "organization_members_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "organization_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      organization_settings: {
        Row: {
          allowed_countries: string[]
          business_hours: Json
          created_at: string
          data_retention_days: number
          organization_id: string
          record_calls: boolean
          supported_locales: string[]
          transcribe_calls: boolean
          updated_at: string
        }
        Insert: {
          allowed_countries?: string[]
          business_hours?: Json
          created_at?: string
          data_retention_days?: number
          organization_id: string
          record_calls?: boolean
          supported_locales?: string[]
          transcribe_calls?: boolean
          updated_at?: string
        }
        Update: {
          allowed_countries?: string[]
          business_hours?: Json
          created_at?: string
          data_retention_days?: number
          organization_id?: string
          record_calls?: boolean
          supported_locales?: string[]
          transcribe_calls?: boolean
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "organization_settings_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: true
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      organizations: {
        Row: {
          country_code: string
          created_at: string
          created_by: string
          default_currency: string
          default_locale: string
          default_timezone: string
          id: string
          name: string
          slug: string
          updated_at: string
        }
        Insert: {
          country_code?: string
          created_at?: string
          created_by: string
          default_currency?: string
          default_locale?: string
          default_timezone?: string
          id?: string
          name: string
          slug: string
          updated_at?: string
        }
        Update: {
          country_code?: string
          created_at?: string
          created_by?: string
          default_currency?: string
          default_locale?: string
          default_timezone?: string
          id?: string
          name?: string
          slug?: string
          updated_at?: string
        }
        Relationships: []
      }
      phone_numbers: {
        Row: {
          assigned_agent_id: string | null
          capabilities: string[]
          country_code: string
          created_at: string
          e164_number: string
          id: string
          label: string | null
          organization_id: string
          provider: string
          provider_number_id: string | null
          status: Database["public"]["Enums"]["phone_number_status"]
          updated_at: string
        }
        Insert: {
          assigned_agent_id?: string | null
          capabilities?: string[]
          country_code: string
          created_at?: string
          e164_number: string
          id?: string
          label?: string | null
          organization_id: string
          provider?: string
          provider_number_id?: string | null
          status?: Database["public"]["Enums"]["phone_number_status"]
          updated_at?: string
        }
        Update: {
          assigned_agent_id?: string | null
          capabilities?: string[]
          country_code?: string
          created_at?: string
          e164_number?: string
          id?: string
          label?: string | null
          organization_id?: string
          provider?: string
          provider_number_id?: string | null
          status?: Database["public"]["Enums"]["phone_number_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "phone_numbers_assigned_agent_id_fkey"
            columns: ["assigned_agent_id"]
            isOneToOne: false
            referencedRelation: "agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "phone_numbers_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          created_at: string
          email: string
          full_name: string | null
          id: string
          locale: string
          timezone: string
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          email: string
          full_name?: string | null
          id: string
          locale?: string
          timezone?: string
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          email?: string
          full_name?: string | null
          id?: string
          locale?: string
          timezone?: string
          updated_at?: string
        }
        Relationships: []
      }
      subscription_plans: {
        Row: {
          billing_interval: string
          code: string
          created_at: string
          currency: string
          description: string | null
          id: string
          included_minutes: number
          is_available: boolean
          is_public: boolean
          max_agents: number
          max_members: number
          max_phone_numbers: number
          name: string
          price_cents: number | null
          updated_at: string
        }
        Insert: {
          billing_interval?: string
          code: string
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          included_minutes?: number
          is_available?: boolean
          is_public?: boolean
          max_agents?: number
          max_members?: number
          max_phone_numbers?: number
          name: string
          price_cents?: number | null
          updated_at?: string
        }
        Update: {
          billing_interval?: string
          code?: string
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          included_minutes?: number
          is_available?: boolean
          is_public?: boolean
          max_agents?: number
          max_members?: number
          max_phone_numbers?: number
          name?: string
          price_cents?: number | null
          updated_at?: string
        }
        Relationships: []
      }
      subscriptions: {
        Row: {
          cancel_at_period_end: boolean
          created_at: string
          current_period_end: string | null
          current_period_start: string
          external_provider: string | null
          external_subscription_id: string | null
          id: string
          organization_id: string
          plan_id: string
          status: Database["public"]["Enums"]["subscription_status"]
          updated_at: string
        }
        Insert: {
          cancel_at_period_end?: boolean
          created_at?: string
          current_period_end?: string | null
          current_period_start?: string
          external_provider?: string | null
          external_subscription_id?: string | null
          id?: string
          organization_id: string
          plan_id: string
          status?: Database["public"]["Enums"]["subscription_status"]
          updated_at?: string
        }
        Update: {
          cancel_at_period_end?: boolean
          created_at?: string
          current_period_end?: string | null
          current_period_start?: string
          external_provider?: string | null
          external_subscription_id?: string | null
          id?: string
          organization_id?: string
          plan_id?: string
          status?: Database["public"]["Enums"]["subscription_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: true
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscriptions_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "subscription_plans"
            referencedColumns: ["id"]
          },
        ]
      }
      usage_records: {
        Row: {
          created_at: string
          id: string
          metric: string
          occurred_at: string
          organization_id: string
          quantity: number
          source_id: string | null
          source_type: string | null
          unit: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          metric: string
          occurred_at?: string
          organization_id: string
          quantity: number
          source_id?: string | null
          source_type?: string | null
          unit: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          metric?: string
          occurred_at?: string
          organization_id?: string
          quantity?: number
          source_id?: string | null
          source_type?: string | null
          unit?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "usage_records_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      workflow_executions: {
        Row: {
          call_session_id: string | null
          created_at: string
          error: string | null
          finished_at: string | null
          id: string
          input: Json
          organization_id: string
          output: Json | null
          started_at: string | null
          status: Database["public"]["Enums"]["execution_status"]
          updated_at: string
          workflow_id: string
        }
        Insert: {
          call_session_id?: string | null
          created_at?: string
          error?: string | null
          finished_at?: string | null
          id?: string
          input?: Json
          organization_id: string
          output?: Json | null
          started_at?: string | null
          status?: Database["public"]["Enums"]["execution_status"]
          updated_at?: string
          workflow_id: string
        }
        Update: {
          call_session_id?: string | null
          created_at?: string
          error?: string | null
          finished_at?: string | null
          id?: string
          input?: Json
          organization_id?: string
          output?: Json | null
          started_at?: string | null
          status?: Database["public"]["Enums"]["execution_status"]
          updated_at?: string
          workflow_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "workflow_executions_call_session_id_fkey"
            columns: ["call_session_id"]
            isOneToOne: false
            referencedRelation: "call_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workflow_executions_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workflow_executions_workflow_id_fkey"
            columns: ["workflow_id"]
            isOneToOne: false
            referencedRelation: "workflows"
            referencedColumns: ["id"]
          },
        ]
      }
      workflows: {
        Row: {
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          name: string
          organization_id: string
          status: Database["public"]["Enums"]["workflow_status"]
          steps: Json
          trigger_config: Json
          trigger_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          name: string
          organization_id: string
          status?: Database["public"]["Enums"]["workflow_status"]
          steps?: Json
          trigger_config?: Json
          trigger_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          name?: string
          organization_id?: string
          status?: Database["public"]["Enums"]["workflow_status"]
          steps?: Json
          trigger_config?: Json
          trigger_type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "workflows_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workflows_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      accept_invitation: { Args: { _token_hash: string }; Returns: string }
      create_organization: {
        Args: {
          _country?: string
          _currency?: string
          _locale?: string
          _name: string
          _slug: string
          _timezone?: string
        }
        Returns: string
      }
      has_org_role: {
        Args: {
          _min: Database["public"]["Enums"]["org_role"]
          _org: string
          _user: string
        }
        Returns: boolean
      }
      is_org_member: { Args: { _org: string; _user: string }; Returns: boolean }
      org_role_rank: {
        Args: { _r: Database["public"]["Enums"]["org_role"] }
        Returns: number
      }
      shares_org_with: {
        Args: { _other: string; _user: string }
        Returns: boolean
      }
    }
    Enums: {
      agent_status: "draft" | "active" | "paused" | "archived"
      call_direction: "inbound" | "outbound"
      call_status:
        | "queued"
        | "ringing"
        | "in_progress"
        | "completed"
        | "failed"
        | "no_answer"
        | "busy"
        | "canceled"
      execution_status:
        | "pending"
        | "running"
        | "succeeded"
        | "failed"
        | "canceled"
      integration_status:
        | "not_connected"
        | "pending"
        | "connected"
        | "error"
        | "disabled"
      invitation_status: "pending" | "accepted" | "revoked" | "expired"
      org_role: "owner" | "admin" | "member" | "viewer"
      phone_number_status:
        | "pending_verification"
        | "active"
        | "suspended"
        | "released"
      subscription_status:
        | "trialing"
        | "active"
        | "past_due"
        | "canceled"
        | "incomplete"
      workflow_status: "draft" | "active" | "paused" | "archived"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      agent_status: ["draft", "active", "paused", "archived"],
      call_direction: ["inbound", "outbound"],
      call_status: [
        "queued",
        "ringing",
        "in_progress",
        "completed",
        "failed",
        "no_answer",
        "busy",
        "canceled",
      ],
      execution_status: [
        "pending",
        "running",
        "succeeded",
        "failed",
        "canceled",
      ],
      integration_status: [
        "not_connected",
        "pending",
        "connected",
        "error",
        "disabled",
      ],
      invitation_status: ["pending", "accepted", "revoked", "expired"],
      org_role: ["owner", "admin", "member", "viewer"],
      phone_number_status: [
        "pending_verification",
        "active",
        "suspended",
        "released",
      ],
      subscription_status: [
        "trialing",
        "active",
        "past_due",
        "canceled",
        "incomplete",
      ],
      workflow_status: ["draft", "active", "paused", "archived"],
    },
  },
} as const
