defmodule RelaxirWeb.RecipeLive.UploadTest do
  use RelaxirWeb.ConnCase, async: true

  import Relaxir.DataHelpers

  describe "handle_params/3" do
    test "updates recipe image filename and redirects", %{conn: conn} do
      # Create a test user and recipe
      user = Relaxir.AccountsFixtures.user_fixture(%{email: "user@example.com", password: "password123"})
      _conn = log_in_user(conn, user)

      # Create a test recipe
      %{recipe: recipe} = recipe(%{})

      # Create a socket with the necessary assigns
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          current_user: user
        }
      }

      # Call handle_params directly with valid parameters
      # This simulates being called as a callback from UploadLive
      {:noreply, updated_socket} = RelaxirWeb.RecipeLive.Upload.handle_params(
        %{"id" => Integer.to_string(recipe.id), "image_filename" => "test.jpg"},
        "/recipes/#{recipe.id}/upload?image_filename=test.jpg",
        socket
      )

      # Verify it redirects to the recipe page
      assert updated_socket.redirected == {:live, :patch, %{kind: :push, to: "/recipes/#{recipe.id}"}}

      # Verify the recipe was updated with the image filename
      updated_recipe = Relaxir.Recipes.get_recipe!(recipe.id)
      assert updated_recipe.image_filename == "test.jpg"
    end
  end
end
