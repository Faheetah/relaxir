module.exports = {
  mode: "jit",
  purge: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        amber: {
          50: "#fffaf0",
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
