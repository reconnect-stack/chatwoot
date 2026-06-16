class Api::V1::Accounts::Captain::PreferencesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :authorize_account_update, only: [:update]

  def show
    render json: preferences_payload
  end

  def update
    params_to_update = captain_params
    @current_account.captain_models = params_to_update[:captain_models] if params_to_update[:captain_models]
    @current_account.captain_features = params_to_update[:captain_features] if params_to_update[:captain_features]
    @current_account.save!
    update_external_assistant_config if params[:external_assistant].present?

    render json: preferences_payload
  end

  private

  def preferences_payload
    {
      providers: Llm::Models.providers,
      models: Llm::Models.models,
      features: features_with_account_preferences,
      external_assistant: external_assistant_payload
    }
  end

  def authorize_account_update
    authorize @current_account, :update?
  end

  def captain_params
    permitted = {}
    permitted[:captain_models] = merged_captain_models if params[:captain_models].present?
    permitted[:captain_features] = merged_captain_features if params[:captain_features].present?
    permitted
  end

  def merged_captain_models
    existing_models = @current_account.captain_models || {}
    existing_models.merge(permitted_captain_models)
  end

  def merged_captain_features
    existing_features = @current_account.captain_features || {}
    existing_features.merge(permitted_captain_features)
  end

  def permitted_captain_models
    params.require(:captain_models).permit(
      :editor, :assistant, :copilot, :label_suggestion,
      :audio_transcription, :help_center_search
    ).to_h.stringify_keys
  end

  def permitted_captain_features
    params.require(:captain_features).permit(
      :editor, :assistant, :copilot, :label_suggestion,
      :audio_transcription, :help_center_search
    ).to_h.stringify_keys
  end

  def permitted_external_assistant_config
    params.require(:external_assistant).permit(
      :enabled, :service_url, :assistant_id, :access_token,
      settings: [:send_conversation_context, :send_contact_details, :send_private_notes]
    ).to_h
  end

  def update_external_assistant_config
    config = @current_account.captain_external_assistant_config || @current_account.build_captain_external_assistant_config
    permitted_config = permitted_external_assistant_config
    settings = permitted_config.delete('settings')
    access_token = permitted_config.delete('access_token')

    config.assign_attributes(permitted_config)
    config.access_token = access_token if access_token.present?
    config.settings = config.settings_with_defaults.merge(settings) if settings.present?
    config.save!
  end

  def external_assistant_payload
    config = @current_account.captain_external_assistant_config
    return default_external_assistant_payload if config.blank?

    {
      enabled: config.enabled,
      service_url: config.service_url,
      assistant_id: config.assistant_id,
      access_token_configured: config.access_token.present?,
      settings: config.settings_with_defaults
    }
  end

  def default_external_assistant_payload
    {
      enabled: false,
      service_url: nil,
      assistant_id: nil,
      access_token_configured: false,
      settings: Captain::ExternalAssistantConfig::DEFAULT_SETTINGS
    }
  end

  def features_with_account_preferences
    preferences = Current.account.captain_preferences
    account_features = preferences[:features] || {}
    account_models = preferences[:models] || {}

    Llm::Models.feature_keys.index_with do |feature_key|
      config = Llm::Models.feature_config(feature_key)
      config.merge(
        enabled: account_features[feature_key] == true,
        selected: account_models[feature_key] || config[:default]
      )
    end
  end
end
