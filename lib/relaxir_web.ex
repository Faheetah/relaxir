defmodule RelaxirWeb do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller, namespace: RelaxirWeb

      import Plug.Conn
      import RelaxirWeb.Gettext
      alias RelaxirWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/relaxir_web/templates",
        namespace: RelaxirWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import RelaxirWeb.Gettext
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {RelaxirWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers
      import RelaxirWeb.LiveHelpers

      import RelaxirWeb.ErrorHelpers
      import RelaxirWeb.Gettext
      alias RelaxirWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
