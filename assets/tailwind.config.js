module.exports = {
  mode: "jit",
  content: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        amber: {
          100: "#f9f2eb",
          200: "#f9d8b8",
          500: "#ffab66",
          600: "#e66700",
          900: "#803900",
        },
        green: {
          100: "#EEFFEE",
          700: "#008800",
        },
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
};
