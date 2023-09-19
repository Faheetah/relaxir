module.exports = {
  mode: "jit",
  content: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        amber: {
          50: "#fffaf0",
          100: "#f7f2ee",
        },
        green: {
          100: "#EEFFEE",
        },
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
};
