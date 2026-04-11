export const sendSuccess = (res, { statusCode = 200, message, data } = {}) => {
  const payload = {
    ok: true,
    message,
  };

  if (data !== undefined) {
    payload.data = data;
  }

  return res.status(statusCode).json(payload);
};

export const sendError = (res, { statusCode = 500, message, error } = {}) => {
  const payload = {
    ok: false,
    message,
  };

  if (error) {
    payload.error = error;
  }

  return res.status(statusCode).json(payload);
};
