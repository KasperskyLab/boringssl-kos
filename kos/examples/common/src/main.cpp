/*
 * © 2024 AO Kaspersky Lab
 * Licensed under the OpenSSL License
 */

#include <common/digest.h>

int main(void)
{ 
    common::PrintMessageDigest("sha256", "Test", "Message", "Hello", "World");
    return EXIT_SUCCESS;
}
