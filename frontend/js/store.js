/*jshint unused:false */

(function (exports) {

    'use strict';

    const STORAGE_KEY = 'default';

    exports.todoStorage = {
        async fetch() {
            const response = await fetch(`${config.backendUrl}/state/${STORAGE_KEY}`)

            return (response.status === 200)
                ? response.json()
                : [];
        },
        async save(todos) {
            const response = await fetch(`${config.backendUrl}/state/${STORAGE_KEY}`, {
                method: "PUT",
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(todos)
            })

            if (response.status !== 200) {
                console.log("error saving state")
                console.log(response.body)
            }
        }
    };

})(window);
