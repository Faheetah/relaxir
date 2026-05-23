defmodule Relaxir.AI.Client do
  @moduledoc """
  OpenAI-compatible API client for AI interactions.
  Uses the already available `Req` library for HTTP requests.
  """

  @spec scan_image(binary(), String.t()) :: {:ok, map()} | {:error, term()}
  def scan_image(image_data, prompt) do
    scan_image(image_data, prompt, nil)
  end

  @spec scan_image(binary(), String.t(), String.t() | nil) :: {:ok, map()} | {:error, term()}
  def scan_image(image_data, prompt, model_override) do
    require Logger
    base_url = Application.get_env(:relaxir, :ai_api_endpoint)
    api_key = Application.get_env(:relaxir, :ai_api_key)
    model = model_override || Application.get_env(:relaxir, :ai_model)

    # Check if configuration is missing
    if is_nil(base_url) or is_nil(api_key) or is_nil(model) do
      Logger.error("AI API configuration missing. Please set AI_API_ENDPOINT, AI_API_KEY, and AI_MODEL environment variables.")
      {:error, :configuration_missing}
    else
      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]

      body = %{
        model: model,
        messages: [
          %{
            role: "user",
            content: [
              %{
                type: "text",
                text: prompt
              },
              %{
                type: "image_url",
                image_url: %{
                  url: "data:image/jpeg;base64,#{image_data}",
                  detail: "low"
                }
              }
            ]
          }
        ],
        max_tokens: 1024,
        temperature: 0.1
      }

      endpoint = Path.join(base_url, "chat/completions")
      Logger.debug("AI API request to: #{endpoint} with model: #{model}")
      case Req.post(endpoint, json: body, headers: headers, receive_timeout: 60_000) do
        {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => content}}]}}} ->
          parse_response(content)

        {:ok, %{status: status, body: body}} ->
          {:error, {:api_error, status, body}}

        {:error, reason} ->
          {:error, {:request_error, reason}}
      end
    end
  end

  @spec list_models() :: {:ok, list(map())} | {:error, term()}
  def list_models() do
    require Logger
    base_url = Application.get_env(:relaxir, :ai_api_endpoint)
    api_key = Application.get_env(:relaxir, :ai_api_key)

    # Check if configuration is missing
    if is_nil(base_url) or is_nil(api_key) do
      Logger.error("AI API configuration missing. Please set AI_API_ENDPOINT and AI_API_KEY environment variables.")
      {:error, :configuration_missing}
    else
      headers = [
        {"Authorization", "Bearer #{api_key}"}
      ]

      endpoint = Path.join(base_url, "models")
      Logger.debug("Fetching models from: #{endpoint}")

      case Req.get(endpoint, headers: headers, receive_timeout: 30_000) do
        {:ok, %{status: 200, body: %{"data" => models}}} when is_list(models) ->
          {:ok, models}

        {:ok, %{status: 200, body: body}} ->
          # Some APIs return models directly without "data" key
          if is_list(body) do
            {:ok, body}
          else
            {:error, {:invalid_response, "Expected list of models"}}
          end

        {:ok, %{status: status, body: body}} ->
          {:error, {:api_error, status, body}}

        {:error, reason} ->
          {:error, {:request_error, reason}}
      end
    end
  end

  defp parse_response(content) when is_nil(content) do
    {:error, {:parse_error, "Empty content"}}
  end

  defp parse_response(content) when is_binary(content) do
    # Try to extract JSON from the response content
    content
    |> String.trim()
    |> extract_json()
    |> Jason.decode()
    |> case do
      {:ok, map} -> {:ok, map}
      {:error, _} -> {:error, {:parse_error, content}}
    end
  end

  defp parse_response(content) do
    {:error, {:parse_error, "Invalid content type: #{inspect(content)}"}}
  end

  defp extract_json(content) when is_nil(content) do
    ""
  end

  defp extract_json(content) when is_binary(content) do
    # Handle markdown code blocks
    content
    |> String.replace(~r/```json\s*/i, "")
    |> String.replace(~r/```\s*/i, "")
    |> String.trim()
  end

  defp extract_json(content) do
    # For non-binary content (numbers, booleans, etc.), convert to string
    to_string(content)
  end

end
